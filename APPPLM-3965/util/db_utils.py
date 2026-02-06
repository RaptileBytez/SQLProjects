from turtle import title
from sqlalchemy import text, Engine
from oracledb import DatabaseError
from dal.connector import OracleConnector
from util.config_loader import load_db_credentials
from util.string_utils import split_name
from typing import Tuple, Optional
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
    print("\nℹ️\tStep 4: Creating database engine...")
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
    print("\nℹ️\tStep 5: Fetching MCODE C_IDs from the Database...")
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

def get_user_group_cids(engine: Engine, ary: np.ndarray)->pd.DataFrame:
    """Fetches C_IDs for User Groups from the database.
    Parameters:
        engine (Engine): SQLAlchemy Engine connected to the database.
        ary (np.ndarray): Array of User Groups.
    Returns:
        pd.DataFrame: DataFrame containing User Group and corresponding C_ID.
    """
    print("\nℹ️\tStep 8: Fetching User Group C_IDs from the Database...")
    ug_list = ary.tolist()
    df_all_ug_cids = pd.DataFrame()

    for chunk in chunk_list(ug_list, 1000):
        ug_qry = f"SELECT C_NAME, C_ID FROM T_GROUP WHERE C_NAME IN ({', '.join(f':ug_{i}' for i in range(len(chunk)))})"
        ug_params = {f'ug_{i}': ug for i, ug in enumerate(chunk)}

        with engine.connect() as conn:
            df_chunk = pd.read_sql(text(ug_qry), conn, params=ug_params)
        df_all_ug_cids = pd.concat([df_all_ug_cids, df_chunk], ignore_index=True)
    df_all_ug_cids.columns = df_all_ug_cids.columns.str.upper()
    return df_all_ug_cids

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
        step_no = 6
    elif group.upper() == 'PC':
        title = 'Product Coordinator'
        step_no = 7
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

def get_usr_cids_by_cic(engine: Engine, ary: np.ndarray) -> pd.DataFrame:
    """Fetches C_IDs for users based on their C_ICs.
    Parameters:
        engine (Engine): SQLAlchemy Engine connected to the database.
        ary (np.ndarray): Array of C_ICs.
    Returns:
        pd.DataFrame: DataFrame containing C_IC and corresponding C_ID.
    """
    print(f"\nℹ️\tFetching user C_IDs by C_ICs from the Database...")
    c_ic_list = ary.tolist()
    df_all_usr_cids = pd.DataFrame()

    for chunk in chunk_list(c_ic_list, 1000):
        qry = text(f"""
            SELECT C_IC, C_ID
            FROM T_USER
            WHERE C_IC IN ({', '.join(f':cic_{i}' for i in range(len(chunk)))})
        """)
        params = {f'cic_{i}': c_ic for i, c_ic in enumerate(chunk)}

        with engine.connect() as conn:
            df_chunk = pd.read_sql(qry, conn, params=params)
        df_all_usr_cids = pd.concat([df_all_usr_cids, df_chunk], ignore_index=True)
    df_all_usr_cids.columns = df_all_usr_cids.columns.str.upper()
    return df_all_usr_cids

def get_prs_data_by_cid(engine: Engine, ary: np.ndarray) -> pd.DataFrame:
    """Fetches person data based on their C_IDs.
    Parameters:
        engine (Engine): SQLAlchemy Engine connected to the database.
        ary (np.ndarray): Array of C_IDs.
    Returns:
        pd.DataFrame: DataFrame containing C_ID, S_USER (last name), S_FIRST_NAME (first name), and C_IC.
    """
    print(f"\nℹ️\tFetching person data by C_IDs from the Database...")
    cid_list = ary.tolist()
    df_all_prs = pd.DataFrame()

    for chunk in chunk_list(cid_list, 1000):
        qry = text(f"""
            SELECT C_ID, S_USER, S_FIRST_NAME, C_IC
            FROM T_PRS_DAT
            WHERE C_ID IN ({', '.join(f':cid_{i}' for i in range(len(chunk)))})
        """)
        params = {f'cid_{i}': cid for i, cid in enumerate(chunk)}

        with engine.connect() as conn:
            df_chunk = pd.read_sql(qry, conn, params=params)
        df_all_prs = pd.concat([df_all_prs, df_chunk], ignore_index=True)
    df_all_prs.columns = df_all_prs.columns.str.upper()
    return df_all_prs

def insert_history_entries(engine: Engine, df_inserts: pd.DataFrame, group: str, DB_PROFILE: str, RUN_MODE: str) -> pd.DataFrame:
    """Inserts new history entries into the specified table.
    Parameters:
        engine (Engine): SQLAlchemy Engine connected to the database.
        df_inserts (pd.DataFrame): DataFrame containing the T_MC_PERSON data.
        group (str): 'PO' for Product Owner or 'PC' for Product Coordinator.
        DB_PROFILE (str): Database profile name for logging purposes.
        RUN_MODE (str): 'DRY_RUN' to simulate inserts without modifying the database.
    Returns:
        pd.DataFrame: The DataFrame of new history entries.
    """
    table_name = 't_mc_his'
    if group.upper() == 'PO':
        title = 'Product Owner'
        step_no = 14
    elif group.upper() == 'PCME_2':
        title = 'Product Coordinator'
        step_no = 17
    elif group.upper() == 'PCME_3':
        title = 'Product Coordinator'
        step_no = 20
    elif group.upper() == 'DO':
        title = 'Demoted Owner'
        step_no = 10
    elif group.upper() == 'DEL':
        title = 'Deleted Person'
        step_no = 12
    else:
        print(f"⚠️Unknown group: {group}")
        return pd.DataFrame() # Return empty DataFrame for unknown group
    next_cid = get_max_cid(engine, table_name) + 1
    next_hist_id = get_max_hist_id(engine, table_name) + 1

    print(f"\nℹ️\tStep {step_no}: Inserting history entry into {table_name.upper()} for group {group.upper()} with C_ID {next_cid} and HIST_ID {next_hist_id}...")    

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
    df_record['C_GIC'] = 2300 # Group: NRLS
    df_record['C_CRE_DAT'] = pd.Timestamp.now().normalize()
    df_record['C_UPD_DAT'] = pd.Timestamp.now().normalize()
    df_record['C_ACC_OGW'] = 'ddr'

    # map columns from df_inserts preserving row order
    df_record['C_ID_1'] = df_inserts['MCODE_CID'].values
    df_record['C_ID_2'] = 0
    df_record['HIST_ID'] = new_hist_ids    

    # build per-row MEMO strings
    if group.upper() == 'PO':
        df_record['FUNCTION'] = 'Inserted'
        df_record['MEMO'] = df_inserts.apply(
            lambda r: f"{r['PO_LAST_NAME']}, {r['PO_FIRST_NAME']} ({r['PO_C_IC']}) - DO - PO", axis=1
        ).values
    elif group.upper() == 'PCME_2':
        df_record['FUNCTION'] = 'Inserted'
        df_record['MEMO'] = df_inserts.apply(
            lambda r: f"{r['PCME2_LAST_NAME']}, {r['PCME2_FIRST_NAME']} ({r['PCME2_C_IC']}) - PC", axis=1
        ).values
    elif group.upper() == 'PCME_3':
        df_record['FUNCTION'] = 'Inserted'
        df_record['MEMO'] = df_inserts.apply(
            lambda r: f"{r['PCME3_LAST_NAME']}, {r['PCME3_FIRST_NAME']} ({r['PCME3_C_IC']}) - PC", axis=1
        ).values
    elif group.upper() == 'DO':
        df_record['FUNCTION'] = 'Updated'
        df_record['MEMO'] = df_inserts.apply(
            lambda r: f"{r['S_USER']}, {r['S_FIRST_NAME']} ({r['C_IC']}) - PO", axis=1
        ).values
    elif group.upper() == 'DEL':
        df_record['FUNCTION'] = 'Removed'
        df_record['MEMO'] = df_inserts.apply(
            lambda r: f"{r['S_USER']}, {r['S_FIRST_NAME']} ({r['C_IC']}) - PO", axis=1
        ).values
    df_record['MODIFY_DATE'] = pd.Timestamp.now()
    df_record['MODIFY_NAME'] = 'PLM_MIGRATOR'
    
    # Insert into database
    if not RUN_MODE.upper() == 'DRY_RUN':
        try:
            df_record.to_sql(
                name=table_name,
                con=engine,
                if_exists='append',
                index=True,
                chunksize=2000,
            )
            rows_inserted = len(df_record)
            print(f"✅\tSuccessfully inserted {rows_inserted} new {title} rows in {table_name.upper()}.")
            df_record.to_csv(f"Data/{DB_PROFILE}_{table_name.upper()}_new_{group.upper()}_history_entries.csv")
            print(f"✅\tNew {title} history entries saved to 'Data/{DB_PROFILE}_{table_name.upper()}_new_{group.upper()}_history_entries.csv'.")
        except Exception as e:
            print(f"❌\tERROR while inserting history entry into {table_name.upper()}: {e}")
    else:
        print(f"ℹ️\tDRY_RUN mode: Skipping actual insert into {table_name.upper()}.")
        df_record.to_csv(f"Data/{DB_PROFILE}_{table_name.upper()}_new_{group.upper()}_history_entries_{RUN_MODE.upper()}.csv")
        print(f"✅\tNew {title} history entries saved to 'Data/{DB_PROFILE}_{table_name.upper()}_new_{group.upper()}_history_entries_{RUN_MODE.upper()}.csv'.")    
    return df_record

def insert_relations(engine: Engine, df_extended: pd.DataFrame, group: str, DB_PROFILE: str, RUN_MODE: str, next_cid: Optional[int] = None) -> Tuple[pd.DataFrame, pd.DataFrame]:
    """
    Inserts new MCODE-Person relationships into the specified table.
    Parameters:
        engine (Engine): SQLAlchemy Engine connected to the database.
        df_extended (pd.DataFrame): DataFrame containing the extended MCODE-Person data.
        group (str): 'PO' for Product Owner or 'PCME_2'/'PCME_3' for Product Coordinator.
        DB_PROFILE (str): Database profile name for logging purposes.
        RUN_MODE (str): 'DRY_RUN' to simulate inserts without modifying the database.
        next_cid (Optional[int]): The next C_ID to use for new entries. If None, it will be fetched from the database.
    Returns:
        pd.DataFrame: The DataFrame of new relationships inserted.
        pd.DataFrame: The DataFrame of demoted owners (only for PO group).
    """
    table_name = 't_mc_person'
    df_default_owners = pd.DataFrame() 
    df_new_assignments = pd.DataFrame()
    
    # --- 1. Konfiguration und dynamische Spaltenwahl ---
    if group.upper() == 'PO':
        title = 'Product Owner'
        cid_col = 'PO_CID'
        step_no = 9
    elif group.upper() == 'PCME_2':
        title = 'Product Coordinator'
        cid_col = 'PCME2_CID'
        step_no = 16
    elif group.upper() == 'PCME_3':        
        title = 'Product Coordinator'
        cid_col = 'PCME3_CID'
        step_no = 19
    else:
        print(f"⚠️ Unknown group: {group}")
        return df_new_assignments, df_default_owners  # Return empty DataFrames for unknown group

    print(f"\nℹ️\tStep {step_no}: Preparing {title} relationships for {group.upper()} in {table_name.upper()}...")

    # --- 2. Datenaufbereitung ---
    # Wir filtern nur die relevanten Spalten und entfernen leere CIDs
    df_insert = df_extended.copy()
    df_insert = df_insert.dropna(subset=['MCODE_CID', cid_col])
    df_insert = df_insert[['MCODE_CID', cid_col]].copy()
    df_insert = df_insert.rename(columns={'MCODE_CID': 'C_ID_1', cid_col: 'C_ID_2'})
    
    # Entferne exakte Dubletten (MCODE + User) im Input-Set
    df_insert = df_insert.drop_duplicates(subset=['C_ID_1', 'C_ID_2'], keep='first')

    if df_insert.empty:
        print(f"ℹ️\tNo MCODE {title} relationships to be added.")
        return df_new_assignments, df_default_owners

    # --- 3. Abgleich mit der Datenbank (Exakte Treffer) ---
    mc_id_list = df_insert['C_ID_1'].unique().tolist()
    df_existing_exact = pd.DataFrame()

    # Chunking um SQL-Limits (z.B. 1000 bei Oracle) zu umgehen
    for chunk in [mc_id_list[i:i + 900] for i in range(0, len(mc_id_list), 900)]:
        query = text(f"SELECT C_ID_1, C_ID_2 FROM {table_name} WHERE C_ID_1 IN ({', '.join(f':m_{j}' for j in range(len(chunk)))})")
        params = {f'm_{j}': m_id for j, m_id in enumerate(chunk)}
        with engine.connect() as conn:
            df_chunk = pd.read_sql(query, conn, params=params)
        
        df_chunk.columns = df_chunk.columns.str.upper()
        df_existing_exact = pd.concat([df_existing_exact, df_chunk], ignore_index=True)

    # Nur Zeilen behalten, die noch NICHT exakt so (MCODE+User) in der DB stehen
    df_merged = df_insert.merge(df_existing_exact, on=['C_ID_1', 'C_ID_2'], how='left', indicator=True)
    df_new_assignments = df_merged[df_merged['_merge'] == 'left_only'].drop(columns=['_merge']).copy()

    if df_new_assignments.empty:
        print(f"ℹ️\tAll {title} relationships already exist in the database.")
        return df_new_assignments, df_default_owners

    # --- 4. DEFAULT OWNER SWITCH (Nur für PO) ---
    if group.upper() == 'PO':
        temp_list = []
        target_mcodes = df_new_assignments['C_ID_1'].unique().tolist()
        
        # Dokumentation: Wer ist aktuell 'y'?
        for chunk in [target_mcodes[i:i + 900] for i in range(0, len(target_mcodes), 900)]:
            check_query = text(f"SELECT * FROM {table_name} WHERE DEF_OWNER = 'y' AND C_ID_1 IN ({', '.join(f':m_{j}' for j in range(len(chunk)))})")
            check_params = {f'm_{j}': m_id for j, m_id in enumerate(chunk)}
            with engine.connect() as conn:
                df_old_owners = pd.read_sql(check_query, conn, params=check_params)
                temp_list.append(df_old_owners)

        if temp_list:
            df_default_owners = pd.concat(temp_list, ignore_index=True)
            df_default_owners.columns = df_default_owners.columns.str.upper()
            df_default_owners = df_default_owners.rename(columns={'C_ID_1': 'MCODE_CID', 'C_ID_2': 'PRS_CID'})
            if not RUN_MODE.upper() == 'DRY_RUN':
                demoted_csv_path = f"Data/BACKUP/{DB_PROFILE}_{table_name.upper()}_BACKUP_{group.upper()}_before_DEMOTION.csv"
            else:
                demoted_csv_path = f"Data/BACKUP/{DB_PROFILE}_{table_name.upper()}_BACKUP_{group.upper()}_before_DEMOTION_{RUN_MODE.upper()}.csv"
            df_default_owners.to_csv(demoted_csv_path, index=False)
            print(f"✅\tSaved {len(df_default_owners)} demoted owners to {demoted_csv_path}")

        # Switch ausführen: Bestehende 'y' auf 'n' setzen
        if not RUN_MODE.upper() == 'DRY_RUN':
            for chunk in [target_mcodes[i:i + 900] for i in range(0, len(target_mcodes), 900)]:
                update_stmt = text(f"""
                    UPDATE {table_name} 
                    SET DEF_OWNER = 'n', C_UPD_DAT = TO_DATE(:now, 'YYYY-MM-DD') 
                    WHERE DEF_OWNER = 'y' 
                    AND C_ID_1 IN ({', '.join(f':m_{j}' for j in range(len(chunk)))})
                """)
                update_params = {f'm_{j}': m_id for j, m_id in enumerate(chunk)}
                update_params['now'] = pd.Timestamp.now().normalize()
                with engine.begin() as conn:
                    conn.execute(update_stmt, update_params)
        
        print(f"✅\tDemoted existing default owners from 'y' to 'n' for {len(target_mcodes)} MCODEs.")
    
    # --- 5. Insert vorbereiten ---
    if next_cid is None:
        next_cid = get_max_cid(engine, table_name) + 1

    df_new_assignments = df_new_assignments.reset_index(drop=True)
    df_new_assignments['C_ID'] = df_new_assignments.index + next_cid
    df_new_assignments['C_VERSION'] = 1
    df_new_assignments['C_LOCK'] = 0
    df_new_assignments['PO'] = 'y' if group.upper() == 'PO' else 'n'
    df_new_assignments['PC'] = 'y' if group.upper().startswith('PC') else 'n'
    df_new_assignments['MO'] = 'n'
    df_new_assignments['DEF_OWNER'] = 'y' if group.upper() == 'PO' else 'n'
    df_new_assignments['C_UIC'] = 1829 # User: PLM_MIGRATOR
    df_new_assignments['C_GIC'] = 2300 # Group: NRLS
    df_new_assignments['C_CRE_DAT'] = pd.Timestamp.now().normalize()
    df_new_assignments['C_UPD_DAT'] = pd.Timestamp.now().normalize()
    df_new_assignments['C_ACC_OGW'] = 'ddr'

    # --- 6. Datenbank Insert ---
    if not RUN_MODE.upper() == 'DRY_RUN':    
        try:
            df_new_assignments.set_index('C_ID').to_sql(
                name=table_name, con=engine, if_exists='append', index=True, chunksize=2000
            )
            print(f"✅\tSuccessfully inserted {len(df_new_assignments)} new {title} entries.")
            df_new_assignments.to_csv(f"Data/{DB_PROFILE}_{table_name.upper()}_new_{group.upper()}_relations.csv", index=False)
            print(f"✅\tNew {title} relationships saved to 'Data/{DB_PROFILE}_{table_name.upper()}_new_{group.upper()}_relations.csv'.")
            
            # --- 7. Zusammenfassung ausgeben ---
            if group.upper() == 'PO':
                print("\n" + "="*60)
                print(f"📊 SUMMARY: {title.upper()} REPLACEMENT")
                print(f"Total new relations: {len(df_new_assignments)}")
                print(f"Owners demoted from 'y' to 'n': {len(df_default_owners)}")
                
                # Zeige Beispiele für den Wechsel
                for _, row in df_default_owners.head(10).iterrows():
                    m_cid = row['MCODE_CID']
                    old_u_cid = row['PRS_CID']
                    # Finde den neuen User für diesen MCODE im Insert-DF
                    new_u_cid = df_new_assignments[df_new_assignments['C_ID_1'] == m_cid]['C_ID_2'].values[0]
                    print(f"  • MCODE {m_cid}: Old DEF_OWNER: {old_u_cid} ➔ NEW DEF_OWNER {new_u_cid}")
                print("="*60 + "\n")

        except Exception as e:
            print(f"❌\tERROR while inserting into {table_name}: {e}")
    else:
        print(f"ℹ️\tDRY_RUN mode: Skipping actual insert into {table_name.upper()}.")
        df_new_assignments.to_csv(f"Data/{DB_PROFILE}_{table_name.upper()}_new_{group.upper()}_relations_{RUN_MODE.upper()}.csv", index=False)
        print(f"✅\tNew {title} relationships saved to 'Data/{DB_PROFILE}_{table_name.upper()}_new_{group.upper()}_relations_{RUN_MODE.upper()}.csv'.")
    
    if group.upper() == 'PO':
        return df_new_assignments, df_default_owners
    else:
        return df_new_assignments,   pd.DataFrame()

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

def insert_group_memberships(engine: Engine, df_inserts: pd.DataFrame, group: str, DB_PROFILE: str, RUN_MODE: str) -> pd.DataFrame:
    """Inserts new group membership entries into the T_GRP_USR table.
    Parameters:
        engine (Engine): SQLAlchemy Engine connected to the database.
        df_inserts (pd.DataFrame): DataFrame containing the group membership data.
        group (str): 'PO' for Product Owner or 'PC' for Product Coordinator.
        DB_PROFILE (str): Database profile name for logging purposes.
        RUN_MODE (str): 'DRY_RUN' to simulate inserts without modifying the database.
    Returns:
        pd.DataFrame: The DataFrame of new group membership entries.
    """
    table_name = 't_grp_usr'
    if group.upper() == 'PO':
        title = 'Product Owner'
        step_no = 15
        cid_col = 'PO_USR_CID'
    elif group.upper() == 'PCME_2':
        title = 'Product Coordinator'
        step_no = 18
        cid_col = 'PCME2_USR_CID'
    elif group.upper() == 'PCME_3':
        title = 'Product Coordinator'
        step_no = 21
        cid_col = 'PCME3_USR_CID'
    else:
        print(f"⚠️Unknown group: {group}")
        return pd.DataFrame() # Return empty DataFrame for unknown group
    
    print(f"\nℹ️\tStep {step_no}: Inserting group memberships into {table_name.upper()} for group {group.upper()}...")
    
    if df_inserts.empty:
        return pd.DataFrame()

    # --- SCHRITT 1: Existierende Relationen prüfen ---
    grp_cid_list = df_inserts['GROUP_CID'].unique().tolist()
    df_existing_all = pd.DataFrame() 
    
    for i, chunk in enumerate(chunk_list(grp_cid_list, 900)):
        existing_query = text(f"SELECT C_ID_1, C_ID_2 FROM {table_name} WHERE C_ID_1 IN ({', '.join(f':mc_{j}' for j in range(len(chunk)))})")
        existing_params = {f'mc_{j}': mc_id for j, mc_id in enumerate(chunk)}
        
        with engine.connect() as conn:
            df_chunk = pd.read_sql(existing_query, conn, params=existing_params)
        
        df_chunk.columns = df_chunk.columns.str.upper()    
        df_existing_all = pd.concat([df_existing_all, df_chunk], ignore_index=True)
    print(f"ℹ️\tFetched {len(df_existing_all)} existing group memberships from {table_name.upper()}.")

    # --- SCHRITT 2: Dubletten aus den Inserts entfernen ---
    # Wir machen einen Left-Join der Inserts gegen die DB-Daten
    df_to_process = df_inserts.merge(
        df_existing_all, 
        left_on=['GROUP_CID', cid_col], 
        right_on=['C_ID_1', 'C_ID_2'], 
        how='left', 
        indicator=True
    )

    # Nur die Zeilen behalten, die noch NICHT in der DB sind
    df_to_process = df_to_process[df_to_process['_merge'] == 'left_only'].copy()
    
    num_new = len(df_to_process)
    skipped = len(df_inserts) - num_new

    if skipped > 0:
        print(f"⚠️\tSkipped {skipped} entries (already existing in {table_name}).")

    if num_new == 0:
        print(f"ℹ️\tNo new {title} relationships to be added.")
        return pd.DataFrame()

    # --- SCHRITT 3: Jetzt erst C_IDs vergeben und df_record bauen ---
    next_cid = get_max_cid(engine, table_name) + 1
    new_c_ids = list(range(next_cid, next_cid + num_new))

    df_record = pd.DataFrame(index=new_c_ids)
    df_record.index.name = 'C_ID'
    
    # Konstante Felder
    df_record['C_VERSION'] = 1
    df_record['C_LOCK'] = 0
    df_record['C_UIC'] = 1829
    df_record['C_GIC'] = 2300 # Group: NRLS
    df_record['C_CRE_DAT'] = pd.Timestamp.now().normalize()
    df_record['C_UPD_DAT'] = pd.Timestamp.now().normalize()
    df_record['C_ACC_OGW'] = 'ddr'
    df_record['C_ACCESS'] = 'd'
    df_record['C_DEF_FLG'] = 'n'

    # Mapping der eigentlichen Daten (Werte aus dem gefilterten df_to_process)
    df_record['C_ID_1'] = df_to_process['GROUP_CID'].values
    df_record['C_ID_2'] = df_to_process[cid_col].values

    print(f"✅\tPrepared {num_new} new entries for insertion.")
    
    if not RUN_MODE.upper() == 'DRY_RUN':
        try:
            df_record.to_sql(
                name=table_name,
                con=engine,
                if_exists='append',
                index=True,
                chunksize=2000,
            )
            rows_inserted = len(df_record)
            print(f"✅\tSuccessfully inserted {rows_inserted} new {title} rows in {table_name.upper()}.")
            df_record.to_csv(f"Data/{DB_PROFILE}_{table_name.upper()}_new_{group.upper()}_relations.csv")
            print(f"✅\tNew {title} relationships saved to 'Data/{DB_PROFILE}_{table_name.upper()}_new_{group.upper()}_relations.csv'.")
        except Exception as e:
            print(f"❌\tERROR during insert: {e}")
            return pd.DataFrame()
    else:
        print(f"ℹ️\tDRY_RUN mode: No data inserted into {table_name.upper()}.")
        df_record.to_csv(f"Data/{DB_PROFILE}_{table_name.upper()}_new_{group.upper()}_relations_{RUN_MODE.upper()}.csv")
        print(f"✅\tNew {title} relationships saved to 'Data/{DB_PROFILE}_{table_name.upper()}_new_{group.upper()}_relations_{RUN_MODE.upper()}.csv'.")

    return df_record

def delete_relations(engine: Engine, df_deletes: pd.DataFrame, group: str, DB_PROFILE: str, RUN_MODE: str) -> pd.DataFrame:
    """Deletes MCODE-Person relationships from the specified table.
    Parameters:
        engine (Engine): SQLAlchemy Engine connected to the database.
        df_deletes (pd.DataFrame): DataFrame containing the MCODE-Person data to delete.
        group (str): 'PO' for Product Owner or 'PCME_2'/'PCME_3' for Product Coordinator.
        DB_PROFILE (str): Database profile name for logging purposes.
        RUN_MODE (str): 'DRY_RUN' to simulate deletions without executing them.
    Returns:
        pd.DataFrame: The DataFrame of deleted relationships.
    """
    table_name = 't_mc_person'
    if group.upper() == 'PO':
        title = 'Product Owner'
        step_no = 20
        cid_col = 'PO_CID'
    elif group.upper() == 'PCME_2':
        title = 'Product Coordinator'
        step_no = 22
        cid_col = 'PCME2_CID'
    elif group.upper() == 'PCME_3':
        title = 'Product Coordinator'
        step_no = 23
        cid_col = 'PCME3_CID'
    elif group.upper() == 'DO':
        title = 'Deleted Owner'
        step_no = 11
        cid_col = 'PRS_CID'
    else:
        print(f"⚠️Unknown group: {group}")
        return pd.DataFrame() # Return empty DataFrame for unknown group
    
    print(f"\nℹ️\tStep {step_no}: Deleting {title} relationships from {table_name.upper()}...")

    if df_deletes.empty:
        return pd.DataFrame()
    
    # --- BACKUP BEFORE DELETE ---
    bck_list = []
    for _, row in df_deletes.iterrows():        
        backup_stmt = text(f"SELECT * FROM {table_name} WHERE C_ID_1 = :mc_cid AND C_ID_2 = :user_cid")
        params = {
            'mc_cid': row['MCODE_CID'],
            'user_cid': row[cid_col]
        }
        with engine.connect() as conn:
            result = conn.execute(backup_stmt, params)
            backup_data = result.fetchall()
            for bck_row in backup_data:
                bck_list.append(dict(bck_row._mapping))
    # --- SAVE BACKUP TO CSV ---
    df_backup = pd.DataFrame(bck_list)
    df_backup.columns = df_backup.columns.str.upper()
    print(f"ℹ️\tBackup data for DELETION: {len(df_backup)} rows saved.")
    if not RUN_MODE.upper() == 'DRY_RUN':
        df_backup.to_csv(f"Data/BACKUP/{DB_PROFILE}_{table_name.upper()}_BACKUP_{group.upper()}_before_DELETION.csv", index=False) 
        print(f"✅\tBackup saved to 'Data/BACKUP/{DB_PROFILE}_{table_name.upper()}_BACKUP_{group.upper()}_before_DELETION.csv'.")
    else:
        df_backup.to_csv(f"Data/BACKUP/{DB_PROFILE}_{table_name.upper()}_BACKUP_{group.upper()}_before_DELETION_{RUN_MODE.upper()}.csv", index=False) 
        print(f"✅\tBackup saved to 'Data/BACKUP/{DB_PROFILE}_{table_name.upper()}_BACKUP_{group.upper()}_before_DELETION_{RUN_MODE.upper()}.csv'.")

    num_deleted = 0
    if not RUN_MODE.upper() == 'DRY_RUN':
        for _, row in df_deletes.iterrows():
            delete_stmt = text(f"DELETE FROM {table_name} WHERE C_ID_1 = :mc_cid AND C_ID_2 = :user_cid")
            params = {
                'mc_cid': row['MCODE_CID'],
                'user_cid': row[cid_col]
            }
            with engine.begin() as conn:
                result = conn.execute(delete_stmt, params)
                num_deleted += result.rowcount
    
        print(f"✅\tSuccessfully deleted {num_deleted} {title} relationships from {table_name.upper()}.")
        df_deletes.to_csv(f"Data/{DB_PROFILE}_{table_name.upper()}_deleted_{group.upper()}_relations.csv", index=False)
        print(f"✅\tDeleted {title} relationships saved to 'Data/{DB_PROFILE}_{table_name.upper()}_deleted_{group.upper()}_relations.csv'.")
    else:
        print(f"ℹ️\tDRY_RUN mode: No data deleted from {table_name.upper()}.")
        df_deletes.to_csv(f"Data/{DB_PROFILE}_{table_name.upper()}_deleted_{group.upper()}_relations_{RUN_MODE.upper()}.csv", index=False)
        print(f"✅\tDeleted {title} relationships saved to 'Data/{DB_PROFILE}_{table_name.upper()}_deleted_{group.upper()}_relations_{RUN_MODE.upper()}.csv'.")
    return df_deletes

def delete_group_memberships(engine: Engine, df_deletes: pd.DataFrame, group:str, DB_PROFILE: str, RUN_MODE: str) -> pd.DataFrame:
    """Deletes Group-User relationships from the specified table.
    Parameters:
        engine (Engine): SQLAlchemy Engine connected to the database.
        df_deletes (pd.DataFrame): DataFrame containing the Group-User data to delete.
        group (str): 'PO' for Product Owner or 'PCME_2'/'PCME_3' for Product Coordinator, or 'DO' for Default Owners.
        DB_PROFILE (str): Database profile name for logging purposes.
        RUN_MODE (str): 'DRY_RUN' to simulate deletions without executing them.
    Returns:
        pd.DataFrame: The DataFrame of deleted relationships.
    """
    table_name = 't_grp_usr'
    if group.upper() == 'PO':
        title = 'Product Owner'
        step_no = 80
        cid_col = 'PO_USR_CID'
    elif group.upper() == 'PCME_2':
        title = 'Product Coordinator'
        step_no = 81
        cid_col = 'PCME2_USR_CID'
    elif group.upper() == 'PCME_3':
        title = 'Product Coordinator'
        step_no = 82
        cid_col = 'PCME3_USR_CID'
    elif group.upper() == 'DO':
        title = 'Default Owner'
        step_no = 13
        cid_col = 'USR_CID'
    else:
        print(f"⚠️Unknown group: {group}")
        return pd.DataFrame() # Return empty DataFrame for unknown group
    
    print(f"\nℹ️\tStep {step_no}: Deleting group memberships from {table_name.upper()} for group {group.upper()}...")
    
    if df_deletes.empty:
        return pd.DataFrame()
    
    # --- BACKUP BEFORE DELETE ---
    bck_list = []
    for _, row in df_deletes.iterrows():        
        backup_stmt = text(f"SELECT * FROM {table_name} WHERE C_ID_1 = :grp_cid AND C_ID_2 = :user_cid")
        params = {
            'grp_cid': row['GROUP_CID'],
            'user_cid': row[cid_col]
        }
        with engine.connect() as conn:
            result = conn.execute(backup_stmt, params)
            backup_data = result.fetchall()
            for bck_row in backup_data:
                bck_list.append(dict(bck_row._mapping))
    
    # --- SAVE BACKUP TO CSV ---
    df_backup = pd.DataFrame(bck_list)
    df_backup.columns = df_backup.columns.str.upper()
    print(f"ℹ️\tBackup data for DELETION: {len(df_backup)} rows saved.")
    if not RUN_MODE.upper() == 'DRY_RUN':
        df_backup.to_csv(f"Data/BACKUP/{DB_PROFILE}_{table_name.upper()}_BACKUP_{group.upper()}_before_DELETION.csv", index=False) 
        print(f"✅\tBackup saved to 'Data/BACKUP/{DB_PROFILE}_{table_name.upper()}_BACKUP_{group.upper()}_before_DELETION.csv'.")
    else:
        df_backup.to_csv(f"Data/BACKUP/{DB_PROFILE}_{table_name.upper()}_BACKUP_{group.upper()}_before_DELETION_{RUN_MODE.upper()}.csv", index=False) 
        print(f"✅\tBackup saved to 'Data/BACKUP/{DB_PROFILE}_{table_name.upper()}_BACKUP_{group.upper()}_before_DELETION_{RUN_MODE.upper()}.csv'.")

    num_deleted = 0
    if not RUN_MODE.upper() == 'DRY_RUN':
        for _, row in df_deletes.iterrows():
            delete_stmt = text(f"DELETE FROM {table_name} WHERE C_ID_1 = :grp_cid AND C_ID_2 = :user_cid")
            params = {
                'grp_cid': row['GROUP_CID'],
                'user_cid': row[cid_col]
            }
            with engine.begin() as conn:
                result = conn.execute(delete_stmt, params)
                num_deleted += result.rowcount
    
        print(f"✅\tSuccessfully deleted {num_deleted} {title} relationships from {table_name.upper()}.")
        df_deletes.to_csv(f"Data/{DB_PROFILE}_{table_name.upper()}_deleted_{group.upper()}_relations.csv", index=False)
        print(f"✅\tDeleted {title} relationships saved to 'Data/{DB_PROFILE}_{table_name.upper()}_deleted_{group.upper()}_relations.csv'.")
    else:
        print(f"ℹ️\tDRY_RUN mode: No data deleted from {table_name.upper()}.")
        df_deletes.to_csv(f"Data/{DB_PROFILE}_{table_name.upper()}_deleted_{group.upper()}_relations_{RUN_MODE.upper()}.csv", index=False)
        print(f"✅\tDeleted {title} relationships saved to 'Data/{DB_PROFILE}_{table_name.upper()}_deleted_{group.upper()}_relations_{RUN_MODE.upper()}.csv'.")
    return df_deletes
    