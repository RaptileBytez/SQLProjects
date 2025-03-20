/**
Initial version of the script to mass update the XServ field (T_MASTER_DAT.SERVICE).
Written by Jesco Wurm (ICP) on 19-03-2025
for APPPLM-3624 - As a service user I want XServ to be updated as preparation for the BOM migration.
*/
SET SERVEROUTPUT ON;

DECLARE
    CURSOR c_master_dat IS
        SELECT SERVICE,
              ART_TYP,
              PART_SUBTYPE,
              C_ID
       FROM T_MASTER_DAT d
       WHERE NOT EXISTS (
           SELECT 1 
           FROM T_MASTER_STR s 
           WHERE s.C_ID_1 = d.C_ID
       )
         AND d.C_ID > 0
         AND d.ART_TYP IN ('A', 'R')
         AND d.MIGRATE = 'y'
         AND d.SERVICE IS NOT NULL
         AND (d.PART_SUBTYPE != 'CPL' OR d.PART_SUBTYPE IS NULL);

    TYPE t_master_dat_rec IS TABLE OF c_master_dat%ROWTYPE;
    v_master_dat_recs t_master_dat_rec;

    v_old_service         T_MASTER_DAT.SERVICE%TYPE;
    v_new_service         T_MASTER_DAT.SERVICE%TYPE := NULL; -- Konstanter Wert
    v_art_typ             T_MASTER_DAT.ART_TYP%TYPE;
    v_part_subtype        T_MASTER_DAT.PART_SUBTYPE%TYPE;
    v_c_id                T_MASTER_DAT.C_ID%TYPE;

    v_new_hist_c_id       T_MASTER_HIS.C_ID%TYPE;
    v_new_hist_c_version  T_MASTER_HIS.C_VERSION%TYPE := 1;
    v_new_hist_c_lock     T_MASTER_HIS.C_LOCK%TYPE := 0;
    v_new_hist_c_uic      T_MASTER_HIS.C_UIC%TYPE := 1829;
    v_new_hist_c_gic      T_MASTER_HIS.C_GIC%TYPE := 100;
    v_new_hist_c_cre_dat  T_MASTER_HIS.C_CRE_DAT%TYPE := SYSDATE;
    v_new_hist_c_upd_dat  T_MASTER_HIS.C_UPD_DAT%TYPE := SYSDATE;
    v_new_hist_c_acc_ogw  T_MASTER_HIS.C_ACC_OGW%TYPE := 'ddr';
    v_new_hist_c_id_2     T_MASTER_HIS.C_ID_2%TYPE := 0;
    v_new_hist_id         T_MASTER_HIS.HIST_ID%TYPE;
    v_new_hist_modify_name T_MASTER_HIS.MODIFY_NAME%TYPE := 'PLM_MIGRATOR';

    v_record_count        NUMBER;
BEGIN
    -- Count affected records
    SELECT COUNT(*)
      INTO v_record_count
      FROM T_MASTER_DAT d
     WHERE NOT EXISTS (
           SELECT 1 
           FROM T_MASTER_STR s 
           WHERE s.C_ID_1 = d.C_ID
       )
       AND d.C_ID > 0
       AND d.ART_TYP IN ('A', 'R')
       AND d.MIGRATE = 'y'
       AND d.SERVICE IS NOT NULL
       AND (d.PART_SUBTYPE != 'CPL' OR d.PART_SUBTYPE IS NULL);

    DBMS_OUTPUT.PUT_LINE('Number of records to be updated: ' || v_record_count);

    OPEN c_master_dat;

    LOOP
        FETCH c_master_dat BULK COLLECT INTO v_master_dat_recs LIMIT 100;

        EXIT WHEN v_master_dat_recs.COUNT = 0;

        FOR i IN 1 .. v_master_dat_recs.COUNT LOOP
            v_old_service := v_master_dat_recs(i).SERVICE;
            v_art_typ := v_master_dat_recs(i).ART_TYP;
            v_part_subtype := v_master_dat_recs(i).PART_SUBTYPE;
            v_c_id := v_master_dat_recs(i).C_ID;

            -- Update the SERVICE-Feldes
            UPDATE T_MASTER_DAT
               SET SERVICE = v_new_service
             WHERE C_ID = v_c_id;

            -- Get the ID values using Sequences
            SELECT T_MASTER_HIS_SEQ.NEXTVAL,
                   T_MASTER_HIS_HSEQ.NEXTVAL
              INTO v_new_hist_c_id, v_new_hist_id
              FROM DUAL;

            -- Add the history entry in T_MASTER_HIS
            INSERT INTO T_MASTER_HIS (
                C_ID,
                C_VERSION,
                C_LOCK,
                C_UIC,
                C_GIC,
                C_CRE_DAT,
                C_UPD_DAT,
                C_ACC_OGW,
                C_ID_1,
                C_ID_2,
                HIST_ID,
                FUNCTION,
                MODIFY_DATE,
                MODIFY_NAME,
                MEMO
            )
            VALUES (
                v_new_hist_c_id,
                v_new_hist_c_version,
                v_new_hist_c_lock,
                v_new_hist_c_uic,
                v_new_hist_c_gic,
                v_new_hist_c_cre_dat,
                v_new_hist_c_upd_dat,
                v_new_hist_c_acc_ogw,
                v_c_id,
                v_new_hist_c_id_2,
                v_new_hist_id,
                'MEMO',
                SYSDATE,
                v_new_hist_modify_name,
                'XServ changed from ' || v_old_service || ' to ' || v_new_service
            );

            -- Ausgabe der Änderung
            IF i <= 10 THEN -- Limit output to first 10 records
                DBMS_OUTPUT.PUT_LINE('PART C_ID: ' || v_c_id ||
                                     ' , HIST_C_ID: ' || v_new_hist_c_id ||
                                     ', Old SERVICE: ' || v_old_service ||
                                     ', New SERVICE: ' || v_new_service ||
                                     ', ART_TYP: ' || v_art_typ ||
                                     ', PART_SUBTYPE: ' || v_part_subtype);
            END IF;
        END LOOP;

        -- Commit after processing each batch
        COMMIT;
    END LOOP;
    CLOSE c_master_dat;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM || ' at ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        ROLLBACK;
END;
/