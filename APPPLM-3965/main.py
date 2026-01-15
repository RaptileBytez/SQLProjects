import pandas as pd
import numpy as np
from util.xslx_utils import read_excel_file
from util.string_utils import normalize_name
from util.db_utils import get_mcode_cids, create_db_engine, test_db_connection, get_person_df, get_prs_cids, insert_relations, insert_history_entries
 
def evaluate_mcodes(unique_MCODE: np.ndarray, df_mcode_cid: pd.DataFrame, DB_PROFILE: str) ->None:
    df_check = pd.DataFrame({'MCODE': unique_MCODE})
    df_merged = df_check.merge(df_mcode_cid, on='MCODE', how='left')
    missing_mcodes = df_merged[df_merged['C_ID'].isna()]['MCODE']
    if missing_mcodes.empty:
        print("✅\tAll MCODEs are existing in the database.")
        return
    print(f"⚠️\tThe following MCODEs are nonexistent in the database {DB_PROFILE}:")
    print(missing_mcodes.tolist())
    missing_mcodes.to_csv(f"Data/{DB_PROFILE}_missing_MCODEs.csv")
    print(f"✅\tMissing MCODE list saved to 'Data/{DB_PROFILE}_missing_MCODEs.csv'.")

def evaluate_prs(df_prs: pd.DataFrame, df_prs_cid: pd.DataFrame, group: str, DB_PROFILE: str) -> None:
    """
    Prüft, welche Product Owner keine C_ID aus der Datenbank bekommen haben.
    df_po muss FIRST_NAME und LAST_NAME enthalten (normalisiert).
    df_po_cid enthält die Matches aus T_PRS_DAT.
    """
    if group.upper() == 'PO':
        title = 'Product Owner'
        lbl_full_name = 'PO_FULL_NAME'
        lbl_first_name = 'PO_FIRST_NAME'
        lbl_last_name = 'PO_LAST_NAME'
        lbl_c_ic = 'PO_C_IC'
    elif group.upper() == 'PC':
        title = 'Product Coordinator'
        lbl_full_name = 'PC_FULL_NAME'
        lbl_first_name = 'PC_FIRST_NAME'
        lbl_last_name = 'PC_LAST_NAME'
        lbl_c_ic = 'PC_C_IC'
        
    # Das DB-Resultat enthält S_FIRST_NAME und S_USER (Nachname)
    df_merged = df_prs.merge(
        df_prs_cid,
        left_on=[lbl_first_name, lbl_last_name],
        right_on=["S_FIRST_NAME", "S_USER"],
        how="left"
    )
    # Alle Einträge ohne C_ID → nicht in DB gefunden
    missing_prs = df_merged[df_merged["C_ID"].isna()][[lbl_first_name, lbl_last_name]]
    if missing_prs.empty:
        print(f"✅\tAll {group} exist in the database.")
        return
    missing_list = []
    print(f"⚠️\tThe following {len(missing_prs)} {title}(s) are nonexistent in the database {DB_PROFILE}:")
    for row in missing_prs.itertuples():
        first = getattr(row, lbl_first_name)
        last = getattr(row, lbl_last_name)
        missing_list.append(f"{first} {last}")
    print(f"⚠️\t{missing_list}")
    missing_prs.to_csv(f"Data/{DB_PROFILE}_missing_{group}s.csv", index=False)
    print(f"✅\tMissing {group} list saved to 'Data/{DB_PROFILE}_missing_{group}s.csv'.")

def main():
    print("Version 1.0.1\n\nHello from APPPLM-3965!\nA script to update MCODE - Product Owner - Product Coordinator relationships in a Agile e6 database based on an Excel file.\nWritten by Jesco Wurm.\n")
    DB_PROFILE = input("Please input the environment you want to update PROD/QS/PQE/BLD? ").strip().upper()
    perform_update = True

    if DB_PROFILE in ['PROD', 'QS', 'PQE', 'BLD']:
       
        df_xlsx = read_excel_file()
        df_xlsx['PO_normalized'] = df_xlsx['PO'].apply(normalize_name)

        # Detect rows where the PO cell was highlighted in yellow in the Excel file.
        # `read_excel_file` adds a boolean column `PO_HIGHLIGHTED` when styles can be read.
        if 'PO_HIGHLIGHTED' in df_xlsx.columns:
            highlighted_idx = df_xlsx.index[df_xlsx['PO_HIGHLIGHTED']].tolist()
            if highlighted_idx:
                # approximate Excel row numbers (header assumed on first row)
                excel_rows = [i + 2 for i in highlighted_idx]
                print(f"ℹ️\tFound {len(highlighted_idx)} PO cells highlighted in yellow.")
                #print(f"ℹ️\tDataFrame indexes: {highlighted_idx}")
                #print(f"ℹ️\tApprox. Excel row numbers: {excel_rows}")
            else:
                print("✔️\tNo highlighted PO cells found in the Excel file.")
        else:
            print("❌\tHighlight information not available (openpyxl may be missing).")
        
        df_MCODEs = pd.DataFrame()
        df_MCODEs['MCODE'] = df_xlsx['MCODE']
        unique_MCODE = df_MCODEs['MCODE'].dropna().unique()
        print("ℹ️\tThe provided Excel File contains:")
        print(f"\t{len(unique_MCODE)} unique MCODEs.")

        df_POs = pd.DataFrame()
        df_POs['PO'] = df_xlsx['PO']
        df_POs['PO_normalized'] = df_POs['PO'].apply(normalize_name)
        unique_PO = df_POs['PO_normalized'].dropna().unique()
        print(f"\t{len(unique_PO)} unique Product Owners.")

        df_PCs = pd.DataFrame()
        df_PCs['PC'] = pd.concat([df_xlsx['PCME2'], df_xlsx['PCME3']], ignore_index=True)
        df_PCs['PC_normalized'] = df_PCs['PC'].apply(normalize_name)
        unique_PC = df_PCs['PC_normalized'].dropna().unique()
        print(f"\t{len(unique_PC)} unique Product Coordinators.")

        engine = create_db_engine(DB_PROFILE)
        test_db_connection(engine)

        df_mcode_cid = get_mcode_cids(engine, unique_MCODE)
        evaluate_mcodes(unique_MCODE, df_mcode_cid, DB_PROFILE)
        
        df_po = get_person_df(unique_PO, 'PO')
        df_po_cid = get_prs_cids(engine, unique_PO, 'PO')     
        evaluate_prs(df_po, df_po_cid, 'PO', DB_PROFILE)

        df_pc = get_person_df(unique_PC, 'PC')
        df_pc_cid = get_prs_cids(engine, unique_PC, 'PC')
        evaluate_prs(df_pc, df_pc_cid, 'PC', DB_PROFILE)
   
        df_extended = df_xlsx.merge(df_mcode_cid, how='left', on='MCODE')
        df_extended = df_extended.rename(columns={'C_ID': 'MCODE_CID'})
        df_extended['MCODE_CID'] = df_extended['MCODE_CID'].astype('Int64')
        df_extended = df_extended[['MCODE', 'MCODE_CID', 'PO', 'PO_normalized', 'PCME2', 'PCME3']]
        df_extended = df_extended.merge(df_po, how= 'left', left_on = 'PO_normalized', right_on='PO_FULL_NAME')
        df_pos_cid_renamed = df_po_cid.rename(columns={
        'S_FIRST_NAME': 'PO_FIRST_NAME',
        'S_USER': 'PO_LAST_NAME',
        'C_ID': 'PO_CID',
        'C_IC': 'PO_C_IC'})
        df_extended = df_extended.merge(df_pos_cid_renamed[['PO_FIRST_NAME', 'PO_LAST_NAME', 'PO_CID', 'PO_C_IC']], how='left', on=['PO_FIRST_NAME', 'PO_LAST_NAME'])
        df_extended['PO_CID'] = df_extended['PO_CID'].astype('Int64')
        df_extended['PO_C_IC'] = df_extended['PO_C_IC'].astype('Int64')
        df_extended = df_extended[['MCODE', 'MCODE_CID', 'PO', 'PO_normalized', 'PO_FIRST_NAME', 'PO_LAST_NAME', 'PO_CID', 'PO_C_IC', 'PCME2', 'PCME3']]
        df_extended['PCME2_normalized'] = df_extended['PCME2'].apply(normalize_name)
        df_extended['PCME3_normalized'] = df_extended['PCME3'].apply(normalize_name)
        df_pcs_cid_renamed = df_pc_cid.rename(columns={
        'S_FIRST_NAME': 'PC_FIRST_NAME',
        'S_USER': 'PC_LAST_NAME',
        'C_ID': 'PC_CID',
        'C_IC': 'PC_C_IC'})
        
        df_pc= df_pc.merge(df_pcs_cid_renamed, how='left', on=['PC_LAST_NAME', 'PC_FIRST_NAME'])
        df_pc['PC_CID'] = df_pc['PC_CID'].astype('Int64')
        df_pc['PC_C_IC'] = df_pc['PC_C_IC'].astype('Int64')

        df_extended = df_extended.merge(df_pc, how='left', left_on= 'PCME2_normalized', right_on='PC_FULL_NAME')
        df_extended = df_extended.rename(columns={'PC_FULL_NAME': 'PCME2_FULL_NAME', 'PC_FIRST_NAME': 'PCME2_FIRST_NAME', 'PC_LAST_NAME': 'PCME2_LAST_NAME', 'PC_CID': 'PCME2_CID', 'PC_C_IC': 'PCME2_C_IC'})
        df_extended = df_extended.merge(df_pc, how='left', left_on= 'PCME3_normalized', right_on='PC_FULL_NAME')
        df_extended = df_extended.rename(columns={'PC_FULL_NAME': 'PCME3_FULL_NAME', 'PC_FIRST_NAME': 'PCME3_FIRST_NAME', 'PC_LAST_NAME': 'PCME3_LAST_NAME', 'PC_CID': 'PCME3_CID', 'PC_C_IC': 'PCME3_C_IC'})
        df_extended = df_extended[['MCODE', 'MCODE_CID', 'PO', 'PO_normalized', 'PO_FIRST_NAME', 'PO_LAST_NAME', 'PO_CID', 'PO_C_IC', 'PCME2', 'PCME2_normalized', 'PCME2_FIRST_NAME', 'PCME2_LAST_NAME', 'PCME2_CID', 'PCME2_C_IC', 'PCME3', 'PCME3_normalized', 'PCME3_FIRST_NAME', 'PCME3_LAST_NAME', 'PCME3_CID', 'PCME3_C_IC']]

        df_highlighted = pd.DataFrame()
        df_highlighted = df_extended.iloc[highlighted_idx]
        df_highlighted = df_highlighted[['MCODE', 'MCODE_CID', 'PO_normalized', 'PO_FIRST_NAME', 'PO_LAST_NAME', 'PO_CID', 'PO_C_IC', 'PCME2_normalized', 'PCME2_FIRST_NAME', 'PCME2_LAST_NAME', 'PCME2_CID', 'PCME2_C_IC', 'PCME3_normalized', 'PCME3_FIRST_NAME', 'PCME3_LAST_NAME','PCME3_CID', 'PCME3_C_IC']]
        
        df_mis_hlight_mcode_cid = df_highlighted[df_highlighted['MCODE_CID'].isna() == True]
        df_mis_hlight_mcode_cid = df_mis_hlight_mcode_cid[['MCODE', 'MCODE_CID']]
        
        df_mis_hlight_po_cid =  df_highlighted[df_highlighted['PO_CID'].isna() == True]
        df_mis_hlight_po_cid = df_mis_hlight_po_cid[['PO_normalized', 'PO_CID']]
        df_mis_hlight_po_cid = df_mis_hlight_po_cid.drop_duplicates()

        df_extended['BOTH_PC_MIS'] = df_extended['PCME2_CID'].isna() & df_extended['PCME3_CID'].isna()
        df_extended.to_csv(f"Data/{DB_PROFILE}_extended_data_before_update.csv", index=False)
        print(f"✅\tExtended data before update saved to 'Data/{DB_PROFILE}_extended_data_before_update.csv'.")
        df_mis_both_pc_cids = df_extended[df_extended['BOTH_PC_MIS']]
        
        if len(df_mis_hlight_mcode_cid) >0:
            print(f"\n❌\t{len(df_mis_hlight_mcode_cid)} highlighted MCODE(s) not found in database {DB_PROFILE}.")
            print(df_mis_hlight_mcode_cid)
            print("💡\tPlease contact PLM Support and have the missing MCODE(s) created.")
            perform_update = False
        
        if len(df_mis_hlight_po_cid) >0:
            print(f"\n❌\t{len(df_mis_hlight_po_cid)} highlighted Product Owner(s) not found in database {DB_PROFILE}.")
            print(df_mis_hlight_po_cid)
            print("💡\tPlease contact PLM Support and have the missing Product Owner(s) created.")
            perform_update = False
        
        if len(df_mis_both_pc_cids) >0:
            print(f"\n❌\tFor {len(df_mis_both_pc_cids)} entrie's in the Excel both Product Coordinators are missing in the database {DB_PROFILE}.")
            print(df_mis_hlight_mcode_cid)
            print("💡\tPlease contact PLM Support and have the missing Product Coordinators created.")
            perform_update = False

        if perform_update:
            next_cid = None                     
            df_inserts_po = insert_relations(engine, df_highlighted, 'PO', DB_PROFILE, next_cid)
            # Merge missing Person Data back into df_inserts_po
            if not df_inserts_po.empty:
                df_keys = df_highlighted[['MCODE_CID','PO_CID', 'PO_FIRST_NAME','PO_LAST_NAME','PO_C_IC']].drop_duplicates().copy()
                df_inserts_po = df_inserts_po.reset_index().merge(df_keys, left_on=['C_ID_1','C_ID_2'], right_on=['MCODE_CID','PO_CID'], how='left').set_index('C_ID')
                df_history_po = insert_history_entries(engine, df_inserts_po, 'PO', DB_PROFILE)
                        
            # Filter PCME2: keep only rows where PCME2_CID is not null and drop duplicates
            df_extended_pcme2 = df_extended[df_extended['PCME2_CID'].notna()].copy()
            df_extended_pcme2 = df_extended_pcme2.drop_duplicates(subset=['MCODE_CID', 'PCME2_CID'], keep='first')

            # Exclude pairs already handled by PCME2 from the PCME3 set to avoid duplicate inserts
            existing_pcme2_pairs = set(zip(df_extended_pcme2['MCODE_CID'], df_extended_pcme2['PCME2_CID']))

            # Filter PCME3: keep only rows where PCME3_CID is not null, drop duplicates and remove pairs present in PCME2
            df_extended_pcme3 = df_extended[df_extended['PCME3_CID'].notna()].copy()
            df_extended_pcme3 = df_extended_pcme3.drop_duplicates(subset=['MCODE_CID', 'PCME3_CID'], keep='first')
            if existing_pcme2_pairs:
                df_extended_pcme3 = df_extended_pcme3[~df_extended_pcme3.apply(lambda r: (r['MCODE_CID'], r['PCME3_CID']) in existing_pcme2_pairs, axis=1)].copy()

            # Insert PCME2 relations
            df_inserts_pcme2 = insert_relations(engine, df_extended_pcme2, 'PCME_2', DB_PROFILE, next_cid)
            if not df_inserts_pcme2.empty:
                df_keys_pc2 = df_extended_pcme2[['MCODE_CID','PCME2_CID', 'PCME2_FIRST_NAME','PCME2_LAST_NAME','PCME2_C_IC']].drop_duplicates().copy()
                df_inserts_pcme2 = df_inserts_pcme2.reset_index().merge(df_keys_pc2, left_on=['C_ID_1','C_ID_2'], right_on=['MCODE_CID','PCME2_CID'], how='left').set_index('C_ID')
                df_history_pcme2 = insert_history_entries(engine, df_inserts_pcme2, 'PCME_2', DB_PROFILE)
            
            df_inserts_pcme3 = insert_relations(engine, df_extended_pcme3, 'PCME_3', DB_PROFILE, next_cid)
            if not df_inserts_pcme3.empty:
                df_keys_pc3 = df_extended_pcme3[['MCODE_CID','PCME3_CID', 'PCME3_FIRST_NAME','PCME3_LAST_NAME','PCME3_C_IC']].drop_duplicates().copy()
                df_inserts_pcme3 = df_inserts_pcme3.reset_index().merge(df_keys_pc3, left_on=['C_ID_1','C_ID_2'], right_on=['MCODE_CID','PCME3_CID'], how='left').set_index('C_ID')
                df_history_pcme3 = insert_history_entries(engine, df_inserts_pcme3, 'PCME_3', DB_PROFILE)

            print(f"\n✅\tDatabase update for {DB_PROFILE} completed successfully.")
        else:
            print(f"\n❌\tDatabase update for {DB_PROFILE} aborted due to missing data.")
    else:
        print(f"❌\t{DB_PROFILE} is an unknown environment.")


if __name__ == "__main__":
    main()
