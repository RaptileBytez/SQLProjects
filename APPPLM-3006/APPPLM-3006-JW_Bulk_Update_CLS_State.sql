/*
===============================================================================
Script Name: APPPLM-3006-JW_Bulk_Update_CStatus_V2.sql
===============================================================================
Description: Bulk Update Script for C-Status (APPPLM-3006)
             with logging into permanent log table.
Author: Jesco Wurm (ICP)
Creation Date: 10-10-2025
Version: 2.0.0
Last Modified: 13-10-2025
Last Modified By: Jesco Wurm (ICP)
--------------------------------------------------------------------------------
Purpose:
    - Update C-Status to 'unclassified' for items without T_GROUP_DAT relation
    - Create a history entry for the updated item
    - LOG the update safely into a dedicated log table (APPPLM_3006_BULK_LOG)
--------------------------------------------------------------------------------
Change History:
- 10-10-2025: Version 1.0.0 - Initial Version
- 10-10-2025: Version 1.0.1 - Improved performance with FORALL bulk processing
- 10-10-2025: Version 1.0.2 - Adding Part Version to the History
- 10-10-2025: Version 1.0.3 - Changing Logging Behavior for MASS DATA
- 10-10-2025: Version 1.0.4 - Increased Batch Size
- 13-10-2025: Version 2.0.0 - Implemented permanent log table for better tracking
===============================================================================
*/
SET SERVEROUTPUT ON SIZE 1000000;

----------------------------------------------------------------------
        -- 1) Preparation: Drop Log Table (if exists)
----------------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE APPPLM_3006_BULK_LOG PURGE';
EXCEPTION
  WHEN OTHERS THEN 
    IF SQLCODE != -942 THEN -- ORA-00942: table or view does not exist
      RAISE;
    END IF;
END;
/
-----------------------------------------------------------------------
        -- 2) Preparation: Create Log Table
-----------------------------------------------------------------------
CREATE TABLE APPPLM_3006_BULK_LOG (
    LOG_ID          NUMBER GENERATED ALWAYS AS IDENTITY, -- Korrekt ab Oracle 12c
    PART_C_ID       NUMBER NOT NULL,
    HIST_C_ID       NUMBER,
    OLD_C_STATUS    VARCHAR2(50) NOT NULL,
    NEW_C_STATUS    VARCHAR2(50) NOT NULL,
    UPDATE_BATCH_DATE TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT APPPLM_3006_BULK_LOG_PK PRIMARY KEY (LOG_ID)
);

----------------------------------------------------------------------
        -- 3) Main Processing Block with improved logging
----------------------------------------------------------------------
DECLARE
    CURSOR c_master_dat IS
        SELECT C_ID,
               PART_VERSION,
               SFS_CLS_STAT
          FROM T_MASTER_DAT d
         WHERE NOT EXISTS (
                   SELECT 1
                     FROM T_GRP_ART g
                    WHERE d.C_ID = g.C_ID_2
               )
           AND d.C_ID > 0
           AND d.SFS_CLS_STAT = 'to be classified';

    TYPE t_master_dat_tab IS TABLE OF c_master_dat%ROWTYPE;
    v_master_dat_recs t_master_dat_tab;
    v_new_c_status CONSTANT T_MASTER_DAT.SFS_CLS_STAT%TYPE := 'unclassified';
    
    -- History Constants
    v_new_hist_c_version CONSTANT T_MASTER_HIS.C_VERSION%TYPE := 1;
    v_new_hist_c_lock CONSTANT T_MASTER_HIS.C_LOCK%TYPE := 0;
    v_new_hist_c_uic CONSTANT T_MASTER_HIS.C_UIC%TYPE := 1829;
    v_new_hist_c_gic CONSTANT T_MASTER_HIS.C_GIC%TYPE := 100;
    v_new_hist_c_acc_ogw CONSTANT T_MASTER_HIS.C_ACC_OGW%TYPE := 'ddr';
    v_new_hist_c_id_2 CONSTANT T_MASTER_HIS.C_ID_2%TYPE := 0;
    v_new_hist_modify_name CONSTANT T_MASTER_HIS.MODIFY_NAME%TYPE := 'PLM_MIGRATOR';
    
    v_record_count NUMBER;
    v_batch_date DATE := SYSDATE;

    -- Sequences for bulk history inserts
    TYPE t_seq_tab IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    v_hist_c_id_tab  t_seq_tab;
    v_hist_id_tab    t_seq_tab;

    -- Temporary table for bulk log data (instead of CLOB/DBMS_OUTPUT)
    TYPE t_log_tab IS TABLE OF APPPLM_3006_BULK_LOG%ROWTYPE;
    v_log_recs t_log_tab := t_log_tab();

BEGIN
    -- Count affected records
    SELECT COUNT(*)
      INTO v_record_count
      FROM T_MASTER_DAT d
     WHERE NOT EXISTS (
               SELECT 1 FROM T_GRP_ART g WHERE d.C_ID = g.C_ID_2
           )
       AND d.C_ID > 0
       AND d.SFS_CLS_STAT = 'to be classified';

    DBMS_OUTPUT.PUT_LINE('Number of records to be updated: ' || v_record_count);

    OPEN c_master_dat;

    LOOP
        FETCH c_master_dat BULK COLLECT INTO v_master_dat_recs LIMIT 2000;
        EXIT WHEN v_master_dat_recs.COUNT = 0;
        
        -- Reset History and Log collections for the new batch
        v_hist_c_id_tab.DELETE;
        v_hist_id_tab.DELETE;
        v_log_recs.DELETE; -- Wichtig: Log-Collection leeren
        v_log_recs.EXTEND(v_master_dat_recs.COUNT); -- Platz reservieren

        ----------------------------------------------------------------------
        -- 3.1) Bulk UPDATE of C-Status
        ----------------------------------------------------------------------
        FORALL i IN INDICES OF v_master_dat_recs
            UPDATE T_MASTER_DAT
               SET SFS_CLS_STAT = v_new_c_status
             WHERE C_ID = v_master_dat_recs(i).C_ID;

        ----------------------------------------------------------------------
        -- 3.2) Prepare History Sequence Values AND Log Records
        ----------------------------------------------------------------------
        FOR i IN 1 .. v_master_dat_recs.COUNT LOOP
            -- Get sequence values for history
            SELECT T_MASTER_HIS_SEQ.NEXTVAL,
                   T_MASTER_HIS_HSEQ.NEXTVAL
              INTO v_hist_c_id_tab(i),
                   v_hist_id_tab(i)
              FROM DUAL;
              
            -- Prepare log record (Part of Step 2 now)
            v_log_recs(i).PART_C_ID := v_master_dat_recs(i).C_ID;
            v_log_recs(i).HIST_C_ID := v_hist_c_id_tab(i);
            v_log_recs(i).OLD_C_STATUS := v_master_dat_recs(i).SFS_CLS_STAT;
            v_log_recs(i).NEW_C_STATUS := v_new_c_status;
            -- UPDATE_BATCH_DATE wird durch DEFAULT SYSTIMESTAMP in der Tabelle gesetzt
        END LOOP;

        ----------------------------------------------------------------------
        -- 3.3) Bulk INSERT into T_MASTER_HIS
        ----------------------------------------------------------------------
        FORALL i IN INDICES OF v_master_dat_recs
            INSERT INTO T_MASTER_HIS (
                C_ID, C_VERSION, C_LOCK, C_UIC, C_GIC, C_CRE_DAT, C_UPD_DAT,
                C_ACC_OGW, C_ID_1, C_ID_2, HIST_ID, CHANGE_NR, "FUNCTION",
                MODIFY_DATE, MODIFY_NAME, MEMO
            )
            VALUES (
                v_hist_c_id_tab(i), v_new_hist_c_version, v_new_hist_c_lock,
                v_new_hist_c_uic, v_new_hist_c_gic, v_batch_date, v_batch_date,
                v_new_hist_c_acc_ogw, v_master_dat_recs(i).C_ID, v_new_hist_c_id_2,
                v_hist_id_tab(i), v_master_dat_recs(i).PART_VERSION, 'MEMO',
                v_batch_date, v_new_hist_modify_name,
                'Classification status changed from ''' || v_master_dat_recs(i).SFS_CLS_STAT
                || ''' to ''' || v_new_c_status || ''' (APPPLM-3006)'
            );

        ----------------------------------------------------------------------
        -- 3.4) Bulk INSERT into Log Table
        ----------------------------------------------------------------------
        FORALL i IN INDICES OF v_log_recs
            INSERT INTO APPPLM_3006_BULK_LOG (
                PART_C_ID,
                HIST_C_ID,
                OLD_C_STATUS,
                NEW_C_STATUS
            )
            VALUES (
                v_log_recs(i).PART_C_ID,
                v_log_recs(i).HIST_C_ID,
                v_log_recs(i).OLD_C_STATUS,
                v_log_recs(i).NEW_C_STATUS
            );
        
        ----------------------------------------------------------------------
        -- 3.5) Commit after each batch
        ----------------------------------------------------------------------
        COMMIT; 
        
    END LOOP;

    CLOSE c_master_dat;
    -----------------------------------------------------------------------
        -- 4) Final Output
    -----------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('Update completed successfully. Total records: ' || v_record_count);
    DBMS_OUTPUT.PUT_LINE('Log entries created in APPPLM_3006_BULK_LOG table.');

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM || ' at '
                             || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        ROLLBACK;
END;
/