from turtle import title
from sqlalchemy import text, Engine
from oracledb import DatabaseError
from dal.connector import OracleConnector
from util.config_loader import load_db_credentials
from util.string_utils import split_name
from typing import Optional
import pandas as pd
import numpy as np

def chunk_list(lst, n):
    """Yield successive n-sized chunks from lst.
    Parameters:
        lst (list): The list to chunk.
        n (int): The size of each chunk.
    Yields:
        list: A chunk of the original list.
    """
    for i in range(0, len(lst), n):
        yield lst[i:i + n]

def test_db_connection(engine: Engine):
    """
    Tests the database connection by executing a simple query.
    Parameters:
        engine (Engine): SQLAlchemy Engine connected to the database.
    Returns:
        None
    """
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1 FROM DUAL"))
            print("✅\tConnection successful.")
    except DatabaseError as dbe:
        print(f"❌\tDatabase Error: {dbe}")

def create_db_engine(profile: str)->Engine:
    """
    Creates a SQLAlchemy Engine for the Oracle database using credentials from the specified profile.
    Parameters:
        profile (str): The profile name in the secrets file.
    Returns:
        Engine: SQLAlchemy Engine connected to the Oracle database.
    Raises:
        DatabaseError: If unable to create the database engine.
    """
    print("\nℹ️\tStep 3: Creating database engine...")
    try:
        creds = load_db_credentials(profile)
        connector = OracleConnector()
        engine = connector.get_oracle_engine(
            username=creds['user'],
            password=creds['password'],
            host=creds['host'],
            port=int(creds['port']),
            service_name=creds['service_name']
        )
        return engine
    
    except Exception as e:
        raise DatabaseError("Unable to create Database Engine.")

def get_mcode_cids(engine: Engine, ary: np.ndarray)->pd.DataFrame:
    """Fetches C_IDs for MCODEs from the database.
    Parameters:
        engine (Engine): SQLAlchemy Engine connected to the database.
        ary (np.ndarray): Array of MCODEs.
    Returns:
        pd.DataFrame: DataFrame containing MCODE and corresponding C_ID.
    """
    print("\nℹ️\tStep 4: Fetching MCODE C_IDs from the Database...")
    mcode_list = ary.tolist()
    df_all_mcode_cids = pd.DataFrame()

    for chunk in chunk_list(mcode_list, 1000):
        mcode_qry = f"SELECT MCODE, C_ID FROM T_SFS_TSL_MC WHERE MCODE IN ({', '.join(f':m_{i}' for i in range(len(chunk)))})"
        mcode_params = {f'm_{i}': mcode for i, mcode in enumerate(chunk)}

        with engine.connect() as conn:
            df_chunk = pd.read_sql(text(mcode_qry), conn, params=mcode_params)
        df_all_mcode_cids = pd.concat([df_all_mcode_cids, df_chunk], ignore_index=True)
    df_all_mcode_cids.columns = df_all_mcode_cids.columns.str.upper()
    return df_all_mcode_cids

def get_max_cid(engine: Engine, table_name: str) -> int:
    """Returns the maximum C_ID from the specified table.
    Parameters:
        engine (Engine): SQLAlchemy Engine connected to the database.
        table_name (str): Name of the table to query.
    Returns:
        int: The maximum C_ID value, or 0 if the table is empty.
    """
    qry = text(f"SELECT MAX(C_ID) FROM {table_name}")
    with engine.connect() as conn:
        result = conn.execute(qry).fetchone()
        if result is None or result[0] is None:
            return 0
        return int(result[0])

def get_max_hist_id(engine: Engine, table_name: str) -> int:
    """Returns the maximum HIST_ID from the specified table.
    Parameters:
        engine (Engine): SQLAlchemy Engine connected to the database.
        table_name (str): Name of the table to query.
    Returns:
        int: The maximum HIST_ID value, or 0 if the table is empty.
    """
    qry = text(f"SELECT MAX(HIST_ID) FROM {table_name}")
    with engine.connect() as conn:
        result = conn.execute(qry).fetchone()
        if result is None or result[0] is None:
            return 0
        return int(result[0])

def get_person_df(ary: np.ndarray, group: str)->pd.DataFrame:
    """Creates a DataFrame of persons with split first and last names.
    Parameters:
        ary (np.ndarray): Array of full names.
        group (str): 'PO' for Product Owner or 'PC' for Product Coordinator.
    Returns:
        pd.DataFrame: DataFrame containing full name, first name, and last name.
    """
    if group.upper() == 'PO':
        lbl_full_name = 'PO_FULL_NAME'
        lbl_first_name = 'PO_FIRST_NAME'
        lbl_last_name = 'PO_LAST_NAME'
    elif group.upper() == 'PC':
        lbl_full_name = 'PC_FULL_NAME'
        lbl_first_name = 'PC_FIRST_NAME'
        lbl_last_name = 'PC_LAST_NAME'
    prs_list = ary.tolist()
    prs_data = []
    for full_name in prs_list:
        first, last = split_name(full_name)
        prs_data.append({lbl_full_name : full_name, lbl_first_name: first, lbl_last_name: last})    
    df_prs = pd.DataFrame(prs_data)
    return df_prs

def get_prs_cids(engine: Engine, ary: np.ndarray, group: str) -> pd.DataFrame:
    """Fetches C_IDs and C_ICs for persons based on their first and last names.
    Parameters:
        engine (Engine): SQLAlchemy Engine connected to the database.
        ary (np.ndarray): Array of full names.
        group (str): 'PO' for Product Owner or 'PC' for Product Coordinator.
    Returns:
        pd.DataFrame: DataFrame containing C_ID, S_USER (last name), S_FIRST_NAME (first name), and C_IC.
    """
    if group.upper() == 'PO':
        title = 'Product Owner'
        step_no = 5
    elif group.upper() == 'PC':
        title = 'Product Coordinator'
        step_no = 6
    print(f"\nℹ️\tStep {step_no}: Fetching {title} C_IDs and C_ICs from the Database...")
    # Split names
    df_po = get_person_df(ary, group)
    # Build OR conditions
    po_tuples = list(df_po.itertuples(index=False, name=None))
    conditions = []
    params = {}
    for i, (n, fn, ln) in enumerate(po_tuples):
        conditions.append(
            f"(LOWER(S_FIRST_NAME) = :fn{i} AND LOWER(S_USER) = :ln{i})"
        )
        params[f"fn{i}"] = fn.lower()
        params[f"ln{i}"] = ln.lower()
    where_clause = " OR ".join(conditions)
    # Build full query
    qry = text(f"""
        SELECT C_ID, S_USER, S_FIRST_NAME, C_IC
        FROM T_PRS_DAT
        WHERE {where_clause}
    """)
    # Step 5: Execute query
    with engine.connect() as conn:
        df_res = pd.read_sql(qry, conn, params=params)
    df_res.columns = df_res.columns.str.upper()
    return df_res

def insert_history_entries(engine: Engine, df_inserts: pd.DataFrame, group: str, DB_PROFILE: str) -> pd.DataFrame:
    """Inserts new history entries into the specified table.
    Parameters:
        engine (Engine): SQLAlchemy Engine connected to the database.
        df_inserts (pd.DataFrame): DataFrame containing the T_MC_PERSON data.
        group (str): 'PO' for Product Owner or 'PC' for Product Coordinator.
        DB_PROFILE (str): Database profile name for logging purposes.
    Returns:
        pd.DataFrame: The DataFrame of new history entries.
    """
    table_name = 't_mc_his'
    if group.upper() == 'PO':
        title = 'Product Owner'
    elif group.upper() == 'PCME_2':
        title = 'Product Coordinator'
    elif group.upper() == 'PCME_3':
        title = 'Product Coordinator'
    else:
        print(f"⚠️Unknown group: {group}")
        return pd.DataFrame() # Return empty DataFrame for unknown group
    next_cid = get_max_cid(engine, table_name) + 1
    next_hist_id = get_max_hist_id(engine, table_name) + 1

    print(f"\nℹ️\tInserting history entry into {table_name} for group {group} with C_ID {next_cid} and HIST_ID {next_hist_id}...")    

    # build history records with same row-order as df_inserts
    num = len(df_inserts)
    if num == 0:
        return pd.DataFrame()

    # generate new C_ID and HIST_ID ranges for the history table
    new_c_ids = list(range(next_cid, next_cid + num))
    new_hist_ids = list(range(next_hist_id, next_hist_id + num))

    # create df_record with index = new C_ID (history table C_ID)
    df_record = pd.DataFrame(index=new_c_ids)
    df_record.index.name = 'C_ID'

    # constant fields (broadcast to all rows)
    df_record['C_VERSION'] = 1
    df_record['C_LOCK'] = 0
    df_record['C_UIC'] = 1829  # User: PLM_MIGRATOR
    df_record['C_GIC'] = 1201  # Group: CONSTRUCTEURS
    df_record['C_CRE_DAT'] = pd.Timestamp.now().normalize()
    df_record['C_UPD_DAT'] = pd.Timestamp.now().normalize()
    df_record['C_ACC_OGW'] = 'ddr'

    # map columns from df_inserts preserving row order
    df_record['C_ID_1'] = df_inserts['C_ID_1'].values
    df_record['C_ID_2'] = 0
    df_record['HIST_ID'] = new_hist_ids
    df_record['FUNCTION'] = 'Inserted'

    # build per-row MEMO strings
    if group.upper() == 'PO':
        df_record['MEMO'] = df_inserts.apply(
            lambda r: f"{r['PO_LAST_NAME']}, {r['PO_FIRST_NAME']} ({r['PO_C_IC']}) - PO", axis=1
        ).values
    elif group.upper() == 'PCME_2':
        df_record['MEMO'] = df_inserts.apply(
            lambda r: f"{r['PCME2_LAST_NAME']}, {r['PCME2_FIRST_NAME']} ({r['PCME2_C_IC']}) - PC", axis=1
        ).values
    elif group.upper() == 'PCME_3':
        df_record['MEMO'] = df_inserts.apply(
            lambda r: f"{r['PCME3_LAST_NAME']}, {r['PCME3_FIRST_NAME']} ({r['PCME3_C_IC']}) - PC", axis=1
        ).values

    df_record['MODIFY_DATE'] = pd.Timestamp.now()
    df_record['MODIFY_NAME'] = 'PLM_MIGRATOR'
       
    try:
        df_record.to_sql(
            name=table_name,
            con=engine,
            if_exists='append',
            index=True,
            chunksize=2000,
        )
        rows_inserted = len(df_record)
        print(f"✅\tSuccessfully inserted {rows_inserted} new {title} rows in {table_name}.")
        df_record.to_csv(f"Data/{DB_PROFILE}_{table_name}_new_{group}_history_entries.csv")
        print(f"✅\tNew {title} history entries saved to 'Data/{DB_PROFILE}_{table_name}_new_{group}_history_entries.csv'.")
    except Exception as e:
        print(f"❌\tERROR while inserting history entry into {table_name}: {e}")
   
    return df_record

def insert_relations(engine: Engine, df_extended: pd.DataFrame, group: str, DB_PROFILE: str, next_cid: Optional[int] = None) -> pd.DataFrame:
    """
    Inserts new MCODE-Person relationships into the specified table.
    Parameters:
        engine (Engine): SQLAlchemy Engine connected to the database.
        df_extended (pd.DataFrame): DataFrame containing the extended MCODE-Person data.
        group (str): 'PO' for Product Owner or 'PCME_2'/'PCME_3' for Product Coordinator.
        DB_PROFILE (str): Database profile name for logging purposes.
        next_cid (Optional[int]): The next C_ID to use for new entries. If None, it will be fetched from the database.
    Returns:
        pd.DataFrame: The DataFrame of new relationships inserted.
    """
    table_name = 't_mc_person'
    if group.upper() == 'PO':
        title = 'Product Owner'
        role_filter = "PO = 'y'" 
        c_id_col = 'PO_CID'
        step_no = 7
    elif group.upper() == 'PCME_2':
        title = 'Product Coordinator'
        role_filter = "PC = 'y'"
        c_id_col = 'PCME2_CID'
        step_no = 8
    elif group.upper() == 'PCME_3':
        title = 'Product Coordinator'
        role_filter = "PC = 'y'"
        c_id_col = 'PCME3_CID'
        step_no = 9
    else:
        print(f"⚠️Unknown group: {group}")
        return pd.DataFrame() # Return empty DataFrame for unknown group
        
    print(f"\nℹ️\tStep {step_no}: Checking MCODE - {title} relationships in the Database...")
    
    df_insert = df_extended.copy()
    df_insert = df_insert.dropna(subset=['MCODE_CID', c_id_col]) 
    df_insert = df_insert[['MCODE_CID', c_id_col]].copy()    
    df_insert = df_insert.rename(columns={'MCODE_CID': 'C_ID_1', c_id_col: 'C_ID_2'})
    # remove exact duplicate pairs before any processing to avoid unique constraint violations
    df_insert = df_insert.drop_duplicates(subset=['C_ID_1', 'C_ID_2'], keep='first')
    df_insert['C_VERSION'] = 1
    df_insert['C_LOCK'] = 0
    if group.upper() == 'PO':
        df_insert['PO'] = 'y'
        df_insert['PC'] = 'n'
        df_insert['MO'] = 'n'
        df_insert['DEF_OWNER'] = 'n'
    else:
        df_insert['PO'] = 'n'
        df_insert['PC'] = 'y'
        df_insert['MO'] = 'n'
        df_insert['DEF_OWNER'] = 'n'
    df_insert['C_UIC'] = 1829 # User: PLM_MIGRATOR
    df_insert['C_GIC'] = 1201 # Group: CONSTRUCTEURS
    df_insert['C_CRE_DAT'] = pd.Timestamp.now().normalize()
    df_insert['C_UPD_DAT'] = pd.Timestamp.now().normalize()
    df_insert['C_ACC_OGW'] = 'ddr'
    initial_count = len(df_insert)
    print(f"ℹ️\tPreparing to check {initial_count} MCODE {title} relations.")
    
    if initial_count == 0:
        print(f"ℹ️\tNo MCODE {title} relationships to be added.")
        return pd.DataFrame()  # Return empty DataFrame if no records to process
        
    mc_id_list = df_insert['C_ID_1'].unique().tolist()
    
    print(f"ℹ️\tChecking {len(mc_id_list)} MCODE-CIDs in the DB for existing {title} relationships...")

    df_existing_all = pd.DataFrame() 
    
    for i, chunk in enumerate(chunk_list(mc_id_list, 900)):
        print(f"ℹ️\tProcessing chunk {i+1} of {len(mc_id_list) // 900 + 1}...")
        
        existing_query = text(f"""
            SELECT C_ID_1, C_ID_2
            FROM {table_name}
            WHERE C_ID_1 IN ({', '.join(f':mc_{j}' for j in range(len(chunk)))})
            AND {role_filter}
        """)

        existing_params = {f'mc_{j}': mc_id for j, mc_id in enumerate(chunk)}
        
        with engine.connect() as conn:
            df_chunk = pd.read_sql(existing_query, conn, params=existing_params)
        
        df_chunk.columns = df_chunk.columns.str.upper()    
        df_existing_all = pd.concat([df_existing_all, df_chunk], ignore_index=True)

    df_merged = df_insert.merge(
        df_existing_all,
        on=['C_ID_1', 'C_ID_2'], 
        how='left', 
        indicator=True
    )
    
    df_new_assignments = df_merged[df_merged['_merge'] == 'left_only'].drop(columns=['_merge'])
    # also ensure no duplicates remain in the new assignments
    df_new_assignments = df_new_assignments.drop_duplicates(subset=['C_ID_1', 'C_ID_2'], keep='first')
    
    new_count = len(df_new_assignments)
    print(f"ℹ️\tFound new {title} relationships to insert: {new_count} (Already existing: {initial_count - new_count}).")
    
    # Use provided next_cid or query database if not provided
    if next_cid is None:
        next_cid = get_max_cid(engine, table_name) + 1
    
    print(f"ℹ️\tStart C_ID for new entries: {next_cid}")
    df_new_assignments = df_new_assignments.reset_index(drop=True)
    df_new_assignments['C_ID'] = df_new_assignments.index + next_cid
    df_new_assignments = df_new_assignments.set_index('C_ID')
    
    if new_count > 0:
        try:
            df_new_assignments.to_sql(
                name=table_name, 
                con=engine, 
                if_exists='append',
                index=True,  
                chunksize=2000,
            )
            rows_inserted = len(df_new_assignments)
            print(f"✅\tSuccessfully inserted {rows_inserted} new {title} rows in {table_name}.")
            df_new_assignments.to_csv(f"Data/{DB_PROFILE}_{table_name}_new_{group}_relations.csv")
            print(f"✅\tNew {title} relationships saved to 'Data/{DB_PROFILE}_{table_name}_new_{group}_relations.csv'.")
            
        except Exception as e:
            print(f"❌\tERROR while inserting new {title} relationships in {table_name}: {e}")
            
    else:
        print(f"ℹ️\tNo new {title} relationships to insert in {table_name}.")
    
    # Return the dataframe of new assignments for further processing if needed
    return df_new_assignments

def get_scm_data(engine: Engine, date: str, DB_PROFILE: str) -> pd.DataFrame:
    """Fetches SCM data created or updated since the specified date.
    Parameters:
        engine (Engine): SQLAlchemy Engine connected to the database.
        date (str): Date string in 'DD-MM-YYYY' format.
        DB_PROFILE (str): Database profile name for logging purposes.
    Returns:
        pd.DataFrame: DataFrame containing SCM data.
    """
    qry = text("""
        SELECT PAT_CHG_ID, MAX(EXPORT_ID) AS MAX_EXPORT_ID
        FROM T_SCM_LOA_MET
        WHERE C_CRE_DAT >= TO_DATE(:date_str, 'DD-MM-YYYY')
        GROUP BY PAT_CHG_ID
    """)
    
    with engine.connect() as conn:
        df_result = pd.read_sql(
            qry, 
            conn, 
            params={'date_str': date}
        )

    df_result = df_result.rename(columns={
        'pat_chg_id': 'PAT_CHG_ID',
        'max_export_id': 'MAX_EXPORT_ID'
    })
    df_result.index.name= 'IDX'
    df_result.to_csv(f"Data/SCM/{DB_PROFILE}_SCMs_since_{date}.csv")
    return df_result