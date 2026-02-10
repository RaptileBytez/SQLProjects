import pandas as pd
import numpy as np
from util.xslx_utils import read_excel_file
from util.string_utils import normalize_name
from util.db_utils import get_mcode_cids, create_db_engine, get_user_group_cids, test_db_connection, get_person_df, get_prs_cids, insert_relations, insert_history_entries, insert_group_memberships, get_prs_data_by_cid, delete_relations, get_usr_cids_by_cic, delete_group_memberships
 
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
        lbl_first_name = 'PO_FIRST_NAME'
        lbl_last_name = 'PO_LAST_NAME'

    elif group.upper() == 'PC':
        title = 'Product Coordinator'
        lbl_first_name = 'PC_FIRST_NAME'
        lbl_last_name = 'PC_LAST_NAME'
           
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
        print(f"✅\tAll {group} are existing in the database {DB_PROFILE}.")
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
    print("Version 1.0.9\n\nHello from APPPLM-3965!\nA script to update MCODE - Product Owner - Product Coordinator relationships in a Agile e6 database based on an Excel file.\nWritten by Jesco Wurm (ICP).\n")
    # --- 1. DRY_RUN Abfrage mit Validierung ---
    while True:
        reply = input("❓\tDo you want to simulate the run aka. DRY_RUN? (Y/N) ").strip().upper()
        if reply in ['Y', 'N']:
            RUN_MODE = 'DRY_RUN' if reply == 'Y' else 'NORMAL'
            status_text = "DRY_RUN mode. No changes will be made." if reply == 'Y' else "NORMAL mode. Changes will be applied."
            print(f"ℹ️\tRunning in {status_text}\n")
            break
        else:
            print("❌\tInvalid input. Please enter 'Y' for Yes or 'N' for No.")

    # --- 2. DB_PROFILE Abfrage mit Validierung ---
    valid_profiles = ['PROD', 'QS', 'PQE', 'BLD']
    while True:
        DB_PROFILE = input(f"❓\tPlease input the environment you want to update ({'/'.join(valid_profiles)})? ").strip().upper()
        if DB_PROFILE in valid_profiles:
            print(f"ℹ️\tEnvironment set to: {DB_PROFILE}")
            break
        else:
            print(f"❌\tInvalid profile '{DB_PROFILE}'. Allowed values are: {', '.join(valid_profiles)}")
    
    if RUN_MODE.upper() == 'NORMAL':
       while True:
           confirm = input(f"\n⚠️\tYou are about to make CHANGES to the {DB_PROFILE} environment.\n⚠️\tMake sure you moved the .csv files in the Data folder to a save location.\n\n❓\tAre you sure to continue? (Y/N) ").strip().upper()
           if confirm == 'Y':
               print("✅\tConfirmation received. Proceeding with updates.\n")
               break
           elif confirm == 'N':
               print("\n❌\tOperation cancelled by user. Exiting.")
               exit()
           else:
               print("❌\tInvalid input. Please enter 'Y' for Yes or 'N' for No.")
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
            else:
                print("✔️\tNo highlighted PO cells found in the Excel file.")
        else:
            print("❌\tHighlight information not available (openpyxl may be missing).")
        
        df_MCODEs = pd.DataFrame()
        df_MCODEs['MCODE'] = df_xlsx['MCODE']
        unique_MCODE = df_MCODEs['MCODE'].dropna().unique()
        print("ℹ️\tThe provided Excel File contains:")
        print(f"ℹ️\t{len(unique_MCODE)} unique MCODEs.")
        
        df_POs = pd.DataFrame()
        df_POs['PO'] = df_xlsx['PO']
        df_POs['PO_normalized'] = df_POs['PO'].apply(normalize_name)
        unique_PO = df_POs['PO_normalized'].dropna().unique()
        print(f"ℹ️\t{len(unique_PO)} unique Product Owners.")

        df_PCs = pd.DataFrame()
        df_PCs['PC'] = pd.concat([df_xlsx['PCME2'], df_xlsx['PCME3']], ignore_index=True)
        df_PCs['PC_normalized'] = df_PCs['PC'].apply(normalize_name)
        unique_PC = df_PCs['PC_normalized'].dropna().unique()
        print(f"ℹ️\t{len(unique_PC)} unique Product Coordinators.")

        print("\nℹ️\tStep 3: Generating Machine Code User Groups for new Groupmembers...")
        mcode_user_groups = [item for mcode in unique_MCODE for item in(f"Y_{mcode}", f"Z_{mcode}")]
        user_groups = np.array(mcode_user_groups)
        print("ℹ️\tThe User Groups list contains:")
        print(f"ℹ️\t{len(user_groups)} User Groups.")

        engine = create_db_engine(DB_PROFILE)
        test_db_connection(engine)

        # Gather MCODE C_IDs
        df_mcode_cid = get_mcode_cids(engine, unique_MCODE)
        evaluate_mcodes(unique_MCODE, df_mcode_cid, DB_PROFILE)

        # Gather PO Information (C_ID, S_USER, S_FIRST_NAME, C_IC, USER_CID) and evaluate
        df_po = get_person_df(unique_PO, 'PO')
        df_po_cid = get_prs_cids(engine, unique_PO, 'PO')
        df_usr_cid = get_usr_cids_by_cic(engine, df_po_cid['C_IC'].dropna().unique())    
        df_po_cid = df_po_cid.merge(df_usr_cid, left_on='C_IC', right_on='C_IC', how='left')
        df_po_cid.rename(columns={'C_ID_x': 'C_ID', 'C_ID_y': 'USR_CID'}, inplace=True)      
        evaluate_prs(df_po, df_po_cid, 'PO', DB_PROFILE)
        
        # Gather PC Information (C_ID, S_USER, S_FIRST_NAME, C_IC, USER_CID) and evaluate
        df_pc = get_person_df(unique_PC, 'PC')
        df_pc_cid = get_prs_cids(engine, unique_PC, 'PC')
        df_usr_cid = get_usr_cids_by_cic(engine, df_pc_cid['C_IC'].dropna().unique()) 
        df_pc_cid = df_pc_cid.merge(df_usr_cid, left_on='C_IC', right_on='C_IC', how='left')
        df_pc_cid.rename(columns={'C_ID_x': 'C_ID', 'C_ID_y': 'USR_CID'}, inplace=True)
        evaluate_prs(df_pc, df_pc_cid, 'PC', DB_PROFILE)

        # Gather User Group C_IDs
        df_usr_grp_cid = get_user_group_cids(engine, user_groups)
        df_usr_grp_cid = df_usr_grp_cid.dropna(subset=['C_ID'])
        df_usr_grp_cid_renamed = df_usr_grp_cid.rename(columns={'C_NAME': 'GROUP_NAME', 'C_ID': 'GROUP_CID'})
        print(f"ℹ️\tRetrieved {len(df_usr_grp_cid_renamed)} User Group C_IDs from database {DB_PROFILE}.")
        drops = len(user_groups) - len(df_usr_grp_cid_renamed)
        if drops >0:
            print(f"ℹ️\tDropped {len(user_groups) - len(df_usr_grp_cid_renamed)} User Groups that do not exist in the {DB_PROFILE} database.")
        else:
            print(f"✅\tAll User Groups are existing in the database {DB_PROFILE}.")

        df_extended = df_xlsx.merge(df_mcode_cid, how='left', on='MCODE')
        df_extended = df_extended.rename(columns={'C_ID': 'MCODE_CID'})
        df_extended['MCODE_CID'] = df_extended['MCODE_CID'].astype('Int64')
        df_extended = df_extended[['MCODE', 'MCODE_CID', 'PO', 'PO_normalized', 'PCME2', 'PCME3']]
        df_extended = df_extended.merge(df_po, how= 'left', left_on = 'PO_normalized', right_on='PO_FULL_NAME')
        df_pos_cid_renamed = df_po_cid.rename(columns={
        'S_FIRST_NAME': 'PO_FIRST_NAME',
        'S_USER': 'PO_LAST_NAME',
        'C_ID': 'PO_CID',
        'C_IC': 'PO_C_IC',
        'USR_CID': 'PO_USR_CID'})
        df_extended = df_extended.merge(df_pos_cid_renamed[['PO_FIRST_NAME', 'PO_LAST_NAME', 'PO_CID', 'PO_C_IC', 'PO_USR_CID']], how='left', on=['PO_FIRST_NAME', 'PO_LAST_NAME'])
        df_extended['PO_CID'] = df_extended['PO_CID'].astype('Int64')
        df_extended['PO_C_IC'] = df_extended['PO_C_IC'].astype('Int64')
        df_extended['PO_USR_CID'] = df_extended['PO_USR_CID'].astype('Int64')
        df_extended = df_extended[['MCODE', 'MCODE_CID', 'PO', 'PO_normalized', 'PO_FIRST_NAME', 'PO_LAST_NAME', 'PO_CID', 'PO_C_IC', 'PO_USR_CID', 'PCME2', 'PCME3']] # Rearranging columns
        
        # Normalize PC names and merge PC C_IDs
        df_extended['PCME2_normalized'] = df_extended['PCME2'].apply(normalize_name)
        df_extended['PCME3_normalized'] = df_extended['PCME3'].apply(normalize_name)
        df_pcs_cid_renamed = df_pc_cid.rename(columns={
        'S_FIRST_NAME': 'PC_FIRST_NAME',
        'S_USER': 'PC_LAST_NAME',
        'C_ID': 'PC_CID',
        'C_IC': 'PC_C_IC',
        'USR_CID': 'PC_USR_CID'})        
        df_pc= df_pc.merge(df_pcs_cid_renamed, how='left', on=['PC_LAST_NAME', 'PC_FIRST_NAME'])

        df_pc['PC_CID'] = df_pc['PC_CID'].astype('Int64')
        df_pc['PC_C_IC'] = df_pc['PC_C_IC'].astype('Int64')
        df_pc['PC_USR_CID'] = df_pc['PC_USR_CID'].astype('Int64')
        df_extended = df_extended.merge(df_pc, how='left', left_on= 'PCME2_normalized', right_on='PC_FULL_NAME')
        df_extended = df_extended.rename(columns={'PC_FULL_NAME': 'PCME2_FULL_NAME', 'PC_FIRST_NAME': 'PCME2_FIRST_NAME', 'PC_LAST_NAME': 'PCME2_LAST_NAME', 'PC_CID': 'PCME2_CID', 'PC_C_IC': 'PCME2_C_IC', 'PC_USR_CID': 'PCME2_USR_CID'})
        df_extended = df_extended.merge(df_pc, how='left', left_on= 'PCME3_normalized', right_on='PC_FULL_NAME')
        df_extended = df_extended.rename(columns={'PC_FULL_NAME': 'PCME3_FULL_NAME', 'PC_FIRST_NAME': 'PCME3_FIRST_NAME', 'PC_LAST_NAME': 'PCME3_LAST_NAME', 'PC_CID': 'PCME3_CID', 'PC_C_IC': 'PCME3_C_IC', 'PC_USR_CID': 'PCME3_USR_CID'})
        df_extended = df_extended[['MCODE', 'MCODE_CID', 'PO', 'PO_normalized', 'PO_FIRST_NAME', 'PO_LAST_NAME', 'PO_CID', 'PO_C_IC', 'PO_USR_CID',  'PCME2', 'PCME2_normalized',  'PCME2_FIRST_NAME',  'PCME2_LAST_NAME',  'PCME2_CID',  'PCME2_C_IC', 'PCME2_USR_CID', 'PCME3', 'PCME3_normalized',  'PCME3_FIRST_NAME',  'PCME3_LAST_NAME',  'PCME3_CID',  'PCME3_C_IC', 'PCME3_USR_CID']] # Rearranging columns

        df_highlighted = pd.DataFrame()
        df_highlighted = df_extended.iloc[highlighted_idx] # Select only highlighted rows
        df_highlighted = df_highlighted[['MCODE', 'MCODE_CID', 'PO_normalized', 'PO_FIRST_NAME', 'PO_LAST_NAME', 'PO_CID', 'PO_C_IC', 'PO_USR_CID', 'PCME2_normalized', 'PCME2_FIRST_NAME', 'PCME2_LAST_NAME', 'PCME2_CID', 'PCME2_C_IC', 'PCME2_USR_CID', 'PCME3_normalized', 'PCME3_FIRST_NAME', 'PCME3_LAST_NAME','PCME3_CID', 'PCME3_C_IC', 'PCME3_USR_CID']]

        df_mis_hlight_mcode_cid = df_highlighted[df_highlighted['MCODE_CID'].isna() == True]
        df_mis_hlight_mcode_cid = df_mis_hlight_mcode_cid[['MCODE', 'MCODE_CID']]
        
        df_mis_hlight_po_cid =  df_highlighted[df_highlighted['PO_CID'].isna() == True]
        df_mis_hlight_po_cid = df_mis_hlight_po_cid[['PO_normalized', 'PO_CID']]
        df_mis_hlight_po_cid = df_mis_hlight_po_cid.drop_duplicates()

        roles = [
                    {'col': 'PO_CID', 'grp_prefix': 'Z_'},
                    {'col': 'PCME2_CID', 'grp_prefix': 'Y_'},
                    {'col': 'PCME3_CID', 'grp_prefix': 'Y_'}
                ]
        temp_list = []
        for role in roles:
            subset = df_extended[['MCODE', 'MCODE_CID',role['col']]].copy()
            subset['GROUP_NAME'] = role['grp_prefix'] + subset['MCODE']
            subset = subset.rename(columns={role['col']: 'USER_CID'})
            temp_list.append(subset)
        df_group_joins = pd.concat(temp_list).dropna(subset=['USER_CID'])
        # Join with group C_IDs
        df_final_grp_joins = pd.merge(df_group_joins, df_usr_grp_cid_renamed,
                                        left_on='GROUP_NAME', right_on='GROUP_NAME', how='left')
        df_final_grp_joins.to_csv(f"Data/{DB_PROFILE}_group_data_before_update.csv", index=False)
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
                                 
            df_inserts_po, df_demoted_records = insert_relations(engine, df_highlighted, 'PO', DB_PROFILE, RUN_MODE=RUN_MODE, next_cid=next_cid)
            if not df_demoted_records.empty:
                ary_unique_demoted_users = df_demoted_records['PRS_CID'].unique()
                if ary_unique_demoted_users.size > 0:
                    df_prs_data = get_prs_data_by_cid(engine, ary_unique_demoted_users)
                    df_demoted_owners = df_demoted_records[['MCODE_CID', 'PRS_CID']].drop_duplicates()
                    # Merge demoted owner names back into df_demoted_owners
                    df_do_ext = df_demoted_owners.merge(df_prs_data, left_on='PRS_CID', right_on='C_ID', how='left')
                    df_do_usr_cid = get_usr_cids_by_cic(engine, df_do_ext['C_IC'].dropna().unique())    
                    # Enrich the data with the USER_CIDs
                    df_do_cid = df_do_ext.merge(df_do_usr_cid, left_on='C_IC', right_on='C_IC', how='left')
                    df_do_cid.rename(columns={'C_ID_x': 'C_ID', 'C_ID_y': 'USR_CID'}, inplace=True)  
                    # Keep only the important columns
                    df_do_ext = df_do_cid[['MCODE_CID', 'PRS_CID', 'S_FIRST_NAME', 'S_USER', 'C_IC', 'USR_CID']]                    
                    # Create the history entries for the demotes users
                    df_history_do = insert_history_entries(engine, df_do_ext, 'DO', DB_PROFILE, RUN_MODE=RUN_MODE)
                    # Delete the demoted users
                    df_deletes_del = delete_relations(engine, df_do_ext, 'DO', DB_PROFILE, RUN_MODE=RUN_MODE)
                    #Create History entries for dthe deleted users
                    df_history_del = insert_history_entries(engine, df_deletes_del, 'DEL', DB_PROFILE, RUN_MODE=RUN_MODE)
                    # Enrich the data with the group data of Z_-Groups the Defaulut owners are still part of
                    df_group_deletes_do = df_do_ext.merge(df_final_grp_joins[df_final_grp_joins['GROUP_NAME'].str.startswith('Z_')][['MCODE_CID', 'GROUP_NAME', 'GROUP_CID']], on='MCODE_CID', how='inner')
                    # Remove those Users from the Z_-Groups
                    df_grp_dels_do = delete_group_memberships(engine, df_group_deletes_do, 'DO', DB_PROFILE, RUN_MODE=RUN_MODE)

            # Merge missing Person Data back into df_inserts_po
            if not df_inserts_po.empty:
                df_keys = df_highlighted[['MCODE_CID','PO_CID', 'PO_FIRST_NAME','PO_LAST_NAME','PO_C_IC', 'PO_USR_CID']].drop_duplicates().copy()
                df_inserts_po = df_inserts_po.reset_index().merge(df_keys, left_on=['C_ID_1','C_ID_2'], right_on=['MCODE_CID','PO_CID'], how='left').set_index('C_ID')

                # Create History Entries for PO
                df_history_po = insert_history_entries(engine, df_inserts_po, 'PO', DB_PROFILE, RUN_MODE=RUN_MODE)
                
                # Sort out group inserts for PO
                df_group_inserts_po = df_final_grp_joins.merge(df_inserts_po[['MCODE_CID', 'PO_CID', 'PO_USR_CID']], left_on=['MCODE_CID', 'USER_CID'], right_on=['MCODE_CID', 'PO_CID'], how='inner')
                df_grp_ins_po = insert_group_memberships(engine, df_group_inserts_po, 'PO', DB_PROFILE, RUN_MODE=RUN_MODE)
            # Reset next_cid for PCME inserts
            next_cid = None
                        
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
            df_inserts_pcme2, df_empty = insert_relations(engine, df_extended_pcme2, 'PCME_2', DB_PROFILE, RUN_MODE=RUN_MODE, next_cid=next_cid)
            if not df_empty.empty:
                print("⚠️\tUnexpected non-empty DataFrame returned for demoted owners from PCME_2 insertion.")

            if not df_inserts_pcme2.empty:
                df_keys_pc2 = df_extended_pcme2[['MCODE_CID','PCME2_CID', 'PCME2_FIRST_NAME','PCME2_LAST_NAME','PCME2_C_IC', 'PCME2_USR_CID']].drop_duplicates().copy()
                df_inserts_pcme2 = df_inserts_pcme2.reset_index().merge(df_keys_pc2, left_on=['C_ID_1','C_ID_2'], right_on=['MCODE_CID','PCME2_CID'], how='left').set_index('C_ID')
                df_history_pcme2 = insert_history_entries(engine, df_inserts_pcme2, 'PCME_2', DB_PROFILE, RUN_MODE=RUN_MODE)
                 
                # Sort out group inserts for PCME2
                df_group_inserts_pcme2 = df_final_grp_joins.merge(df_inserts_pcme2[['MCODE_CID', 'PCME2_CID', 'PCME2_USR_CID']], left_on=['MCODE_CID', 'USER_CID'], right_on=['MCODE_CID', 'PCME2_CID'], how='inner')
                df_grp_ins_pcme2 = insert_group_memberships(engine, df_group_inserts_pcme2, 'PCME_2', DB_PROFILE, RUN_MODE=RUN_MODE)              
            # Reset next_cid for PCME inserts
            next_cid = None

            df_inserts_pcme3, df_empty = insert_relations(engine, df_extended_pcme3, 'PCME_3', DB_PROFILE, RUN_MODE=RUN_MODE, next_cid=next_cid)
            if not df_empty.empty:
                print("⚠️\tUnexpected non-empty DataFrame returned for demoted owners from PCME_3 insertion.")

            if not df_inserts_pcme3.empty:
                df_keys_pc3 = df_extended_pcme3[['MCODE_CID','PCME3_CID', 'PCME3_FIRST_NAME','PCME3_LAST_NAME','PCME3_C_IC', 'PCME3_USR_CID']].drop_duplicates().copy()
                df_inserts_pcme3 = df_inserts_pcme3.reset_index().merge(df_keys_pc3, left_on=['C_ID_1','C_ID_2'], right_on=['MCODE_CID','PCME3_CID'], how='left').set_index('C_ID')
                df_history_pcme3 = insert_history_entries(engine, df_inserts_pcme3, 'PCME_3', DB_PROFILE, RUN_MODE=RUN_MODE)
                # Sort out group inserts for PCME3
                df_group_inserts_pcme3 = df_final_grp_joins.merge(df_inserts_pcme3[['MCODE_CID', 'PCME3_CID', 'PCME3_USR_CID']], left_on=['MCODE_CID', 'USER_CID'], right_on=['MCODE_CID', 'PCME3_CID'], how='inner')
                df_grp_ins_pcme3 = insert_group_memberships(engine, df_group_inserts_pcme3, 'PCME_3', DB_PROFILE, RUN_MODE=RUN_MODE)
            # Reset next_cid for further inserts
            next_cid = None

            if not RUN_MODE == 'DRY_RUN':
                print(f"\n✅\tDatabase update for {DB_PROFILE} completed successfully.")
            else:
                print(f"\n✅\tDRY_RUN completed for {DB_PROFILE}. No changes were made to the database.")
        else:
            print(f"\n❌\tDatabase update for {DB_PROFILE} aborted due to missing data.")
    else:
        print(f"❌\t{DB_PROFILE} is an unknown environment.")


if __name__ == "__main__":
    main()
