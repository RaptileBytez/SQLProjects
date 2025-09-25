/*
===============================================================================
Script Name: APPPLM-3672-JW_PT1_Dublicate_ELEM_ID.sql
===============================================================================
Description:   Report for duplicate ELEM_IDs in T_EWO_DAT that cannot be updated 
               automatically with the APPPLM-3672-JW_PT2_Update_T_EWO_DAT_SCR_FLAG.sql 
               script.
Author:        Jesco Wurm (ICP)
Creation Date: 24-09-2025
Version:        1.0.0
Last Modified: 24-09-2025
Last Modified By: Jesco Wurm (ICP)
--------------------------------------------------------------------------------
Purpose: 
This script will 
- create a report of all duplicate ELEM_IDs in T_EWO_DAT where the SCR flag in
   T_EWR_DAT is about to be set to the related T_EWR_DAT.SCR falg.
--------------------------------------------------------------------------------  
Change History:
===============================================================================
 */
SET SERVEROUTPUT ON

DECLARE
BEGIN
  -- Iterate over all ELEM_IDs that exist multiple times in T_EWO_DAT
  FOR rec IN (
    SELECT
      B.ELEM_ID,
      A.SCR AS EWR_SCR_Flag
    FROM
      T_EWO_DAT B
      INNER JOIN T_EWR_DAT A ON B.ELEM_ID = A.ELEM_ID
    GROUP BY
      B.ELEM_ID, A.SCR
    HAVING
      COUNT(B.ELEM_ID) > 1
  )
  LOOP
    -- Write ELEM_ID and its EWR SCR status to output
    DBMS_OUTPUT.PUT_LINE('Multiple ELEM_ID: ' || rec.ELEM_ID || ', EWR-SCR-Flag: ' || rec.EWR_SCR_Flag);
  END LOOP;
END;
/