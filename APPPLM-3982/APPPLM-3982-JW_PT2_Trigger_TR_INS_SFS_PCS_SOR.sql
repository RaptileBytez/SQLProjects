/*
===============================================================================
Script Name: APPPLM-3982-JW_PT2_Trigger_TR_INS_SFS_PCS_SOR.sql
===============================================================================
Description: Create trigger TR_INS_SFS_PCS_SOR for insert operations on view V_SFS_PCS_SOR
Author: Jesco Wurm (ICP)
Creation Date: 22-12-2025
Version: 1.0.0
Last Modified: 22-12-2025
Last Modified By: Jesco Wurm (ICP)
--------------------------------------------------------------------------------
Purpose: 
This script will 
    - Create or replace the trigger TR_INS_SFS_PCS_SOR to handle insert operations on the view V_SFS_PCS_SOR.
    - The trigger will insert data into the underlying table T_SFS_PCS_SOR except for the virtual column VIR_COL_IC.
    - This enables proper data insertion by the Agile e6 PLM system using standard mask functions.
--------------------------------------------------------------------------------  
Change History:
Date          Author                Version     Description
22-12-2025    Jesco Wurm (ICP)      1.0.0       Initial creation
===============================================================================
 */
CREATE OR REPLACE TRIGGER TR_INS_SFS_PCS_SOR
INSTEAD OF INSERT ON V_SFS_PCS_SOR
FOR EACH ROW
BEGIN
  INSERT INTO T_SFS_PCS_SOR (
    C_ID,
    C_VERSION,
    C_LOCK,
    C_UIC,
    C_GIC,
    C_CRE_DAT,
    C_UPD_DAT,
    C_ACC_OGW,
    TOP_CAT,
    SORTING,
    TOP_CAT_DESCR,
    IC_POULTRY,
    IC_FISH,
    IC_MEAT,
    IC_FP,
    PG
  )
  VALUES (
    :NEW.C_ID,
    :NEW.C_VERSION,
    :NEW.C_LOCK,
    :NEW.C_UIC,
    :NEW.C_GIC,
    :NEW.C_CRE_DAT,
    :NEW.C_UPD_DAT,
    :NEW.C_ACC_OGW,
    :NEW.TOP_CAT,
    :NEW.SORTING,
    :NEW.TOP_CAT_DESCR,
    :NEW.IC_POULTRY,
    :NEW.IC_FISH,
    :NEW.IC_MEAT,
    :NEW.IC_FP,
    :NEW.PG
  );
END;
/