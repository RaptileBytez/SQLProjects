-- ============================================================
-- Script: Fix invalid C_IDs in a given table
-- Description: Finds the smallest sufficient gap for
--              C_IDs > 1999999999 and moves them into it
-- Author: Jesco Wurm (ICP)
-- Date: 26.03.2026
-- ============================================================
SET SERVEROUTPUT ON SIZE UNLIMITED;

DECLARE
    v_table_name        VARCHAR2(100) := 'T_GRP_USR';  -- << Adjust Table Name If necessary
    v_invalid_count     NUMBER;
    v_gap_start         NUMBER;
    v_gap_end           NUMBER;
    v_gap_size          NUMBER;
    v_updated_count     NUMBER;
    v_remaining_count   NUMBER;
    v_sql               VARCHAR2(4000);
BEGIN
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('Table              : ' || v_table_name);
    DBMS_OUTPUT.PUT_LINE('============================================');

    -- Step 1: Count invalid C_IDs
    v_sql := 'SELECT COUNT(*) FROM ' || v_table_name || ' WHERE C_ID > 1999999999';
    EXECUTE IMMEDIATE v_sql INTO v_invalid_count;
    DBMS_OUTPUT.PUT_LINE('Invalid C_IDs found: ' || v_invalid_count);

    IF v_invalid_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No invalid C_IDs found. Nothing to do.');
        RETURN;
    END IF;

    -- Step 2: Find smallest sufficient gap
    DBMS_OUTPUT.PUT_LINE('Searching for sufficient gap...');
    v_sql := '
        SELECT gap_start, gap_end, gap_size
        FROM (
            SELECT 
                gap_start,
                gap_end,
                gap_end - gap_start + 1 AS gap_size
            FROM (
                SELECT 
                    C_ID + 1 AS gap_start,
                    LEAD(C_ID) OVER (ORDER BY C_ID) - 1 AS gap_end
                FROM ' || v_table_name || '
                WHERE C_ID <= 1999999999
            )
            WHERE gap_end >= gap_start
        )
        WHERE gap_size >= :1
        ORDER BY gap_size ASC
        FETCH FIRST 1 ROW ONLY';

    EXECUTE IMMEDIATE v_sql INTO v_gap_start, v_gap_end, v_gap_size USING v_invalid_count;

    DBMS_OUTPUT.PUT_LINE('Gap start          : ' || v_gap_start);
    DBMS_OUTPUT.PUT_LINE('Gap end            : ' || v_gap_end);
    DBMS_OUTPUT.PUT_LINE('Gap size           : ' || v_gap_size);

    -- Step 3: Verify gap is truly empty
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Validating gap is empty...');
    v_sql := 'SELECT COUNT(*) FROM ' || v_table_name || 
             ' WHERE C_ID BETWEEN :1 AND :2';
    EXECUTE IMMEDIATE v_sql INTO v_gap_size USING v_gap_start, v_gap_end;

    IF v_gap_size > 0 THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Gap contains ' || v_gap_size || 
                             ' existing records. Aborting.');
        ROLLBACK;
        RETURN;
    END IF;
    DBMS_OUTPUT.PUT_LINE('Gap validation passed.');

    -- Step 4: Perform the update
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Starting update...');
    v_sql := '
        UPDATE ' || v_table_name || ' orig
        SET C_ID = (
            SELECT :1 + rn - 1
            FROM (
                SELECT C_ID, ROW_NUMBER() OVER (ORDER BY C_ID) AS rn
                FROM ' || v_table_name || '
                WHERE C_ID > 1999999999
            ) sub
            WHERE sub.C_ID = orig.C_ID
        ),
        C_UPD_DAT = SYSDATE
        WHERE C_ID > 1999999999';
    EXECUTE IMMEDIATE v_sql USING v_gap_start;

    v_updated_count := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE('Records updated    : ' || v_updated_count);

    -- Step 5: Final validation
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Running final validation...');
    v_sql := 'SELECT COUNT(*) FROM ' || v_table_name || ' WHERE C_ID > 1999999999';
    EXECUTE IMMEDIATE v_sql INTO v_remaining_count;

    IF v_remaining_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || v_remaining_count || 
                             ' invalid C_IDs remain after update. Rolling back.');
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ROLLBACK executed.');
    ELSIF v_updated_count != v_invalid_count THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Expected ' || v_invalid_count || 
                             ' updates but got ' || v_updated_count || 
                             '. Rolling back.');
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ROLLBACK executed.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Final validation passed.');
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('============================================');
        DBMS_OUTPUT.PUT_LINE('COMMIT successful. ' || v_updated_count || 
                             ' records fixed.');
        DBMS_OUTPUT.PUT_LINE('============================================');
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: No sufficient gap found for ' || 
                             v_invalid_count || ' records. Aborting.');
        ROLLBACK;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Unexpected error: ' || SQLERRM);
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ROLLBACK executed.');
END;
/