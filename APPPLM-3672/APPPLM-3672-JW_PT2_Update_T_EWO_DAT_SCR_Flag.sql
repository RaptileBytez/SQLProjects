/*
===============================================================================
Script Name: APPPLM-3672-JW_PT2_Update_T_EWO_DAT_SCR_Flag.sql
===============================================================================
Description:   Update T_EWO_DAT.SCR flag based on T_EWR_DAT.SCR flag, except for 
               ELEM_IDs that exist multiple times in T_EWO_DAT. These will be 
               reported with the APPPLM-3672-JW_PT1_Dublicate_ELEM_ID_Report.sql script.
Author:        Jesco Wurm (ICP)
Creation Date: 24-09-2025
Version:        1.0.0
Last Modified: 24-09-2025
Last Modified By: Jesco Wurm (ICP)
--------------------------------------------------------------------------------
Purpose: 
This script will 
- update the SCR flag in T_EWO_DAT based on the SCR flag in T_EWR_DAT for all ELEM_IDs 
    that exist only once in T_EWO_DAT.
- print out all updated ELEM_IDs and their new SCR value.
--------------------------------------------------------------------------------  
Change History:
===============================================================================
 */
/*
===============================================================================
Script Name: APPPLM-3672-JW_PT2_Update_T_EWO_DAT_SCR_Flag.sql
===============================================================================
Description:    Update T_EWO_DAT.SCR flag based on T_EWR_DAT.SCR flag, except for
                ELEM_IDs that exist multiple times in T_EWO_DAT. These will be
                reported with the APPPLM-3672-JW_PT1_Dublicate_ELEM_ID_Report.sql script.
Author:         Jesco Wurm (ICP)
Creation Date: 24-09-2025
Version:         1.0.1
Last Modified: 24-09-2025
Last Modified By: Jesco Wurm (ICP)
--------------------------------------------------------------------------------
Purpose:
This script will
- update the SCR flag in T_EWO_DAT based on the SCR flag in T_EWR_DAT for all ELEM_IDs
    that exist only once in T_EWO_DAT.
- print out all updated ELEM_IDs and their new SCR value.
--------------------------------------------------------------------------------  
Change History:
Version    Date        Author         Description
V1.0.0    24-09-2025  Jesco Wurm    Initial creation
V1.0.1    24-09-2025  Jesco Wurm    Redesigne from MERGE to CURSER due to limitation of RETURNING clause in Oracle
===============================================================================
  */
SET SERVEROUTPUT ON;

DECLARE
  -- cursor to select C_IDs from T_EWO_DAT along with their corresponding SCR values from T_EWR_DAT
  CURSOR c_updates IS
    SELECT
      ewo.C_ID,
      src.EWR_SCR
    FROM
      T_EWO_DAT ewo
    INNER JOIN (
      -- Query to get the SCR values from T_EWR_DAT joined with T_EWO_EWR
      SELECT
        ee.C_ID_1,
        ewr.SCR AS EWR_SCR
      FROM
        T_EWR_DAT ewr
      INNER JOIN
        T_EWO_EWR ee ON ewr.C_ID = ee.C_ID_2
      WHERE
        ewr.SCR IS NOT NULL
    ) src ON (ewo.C_ID = src.C_ID_1);

  -- variable to count updated rows
  updated_count NUMBER := 0;

BEGIN
  -- Iterate over the cursor results
  FOR rec IN c_updates LOOP
    -- execute the update statement
    UPDATE T_EWO_DAT
    SET SCR = rec.EWR_SCR
    WHERE C_ID = rec.C_ID;

    -- increment the count of updated rows
    updated_count := updated_count + 1;
    
    -- log the updated C_ID and new SCR value
    DBMS_OUTPUT.PUT_LINE(
      'Updated C_ID: ' || rec.C_ID ||
      ', Neuer SCR-Wert: ' || rec.EWR_SCR
    );
  END LOOP;
  
  -- save changes
  COMMIT;
  
  -- print summary
  DBMS_OUTPUT.PUT_LINE(CHR(10) || '------------------------------');
  DBMS_OUTPUT.PUT_LINE('Gesamte Anzahl der aktualisierten Zeilen: ' || updated_count);
END;
/