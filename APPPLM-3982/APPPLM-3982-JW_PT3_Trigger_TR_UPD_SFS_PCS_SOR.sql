/*
===============================================================================
Script Name: APPPLM-3982-JW_PT3_Trigger_TR_UPD_SFS_PCS_SOR.sql
===============================================================================
Description: Create trigger TR_UPD_SFS_PCS_SOR for update operations on view V_SFS_PCS_SOR
Author: Jesco Wurm (ICP)
Creation Date: 22-12-2025
Version: 1.0.0
Last Modified: 22-12-2025
Last Modified By: Jesco Wurm (ICP)
--------------------------------------------------------------------------------
Purpose: 
This script will 
    - Create or replace the trigger TR_UPD_SFS_PCS_SOR to handle update operations on the view V_SFS_PCS_SOR.
    - The trigger will update data in the underlying table T_SFS_PCS_SOR except for the virtual column VIR_COL_IC.
    - This enables proper data updates by the Agile e6 PLM system using standard mask functions.
--------------------------------------------------------------------------------  
Change History:
Date          Author                Version     Description
22-12-2025    Jesco Wurm (ICP)      1.0.0       Initial creation
===============================================================================
 */
CREATE OR REPLACE TRIGGER TR_UPD_SFS_PCS_SOR
INSTEAD OF UPDATE ON V_SFS_PCS_SOR
FOR EACH ROW
BEGIN
  UPDATE T_SFS_PCS_SOR
  SET
    C_VERSION       = :NEW.C_VERSION,
    C_LOCK          = :NEW.C_LOCK,
    C_UIC           = :NEW.C_UIC,
    C_GIC           = :NEW.C_GIC,
    C_CRE_DAT       = :NEW.C_CRE_DAT,
    C_UPD_DAT       = :NEW.C_UPD_DAT,
    C_ACC_OGW       = :NEW.C_ACC_OGW,
    TOP_CAT         = :NEW.TOP_CAT,
    SORTING         = :NEW.SORTING,
    TOP_CAT_DESCR   = :NEW.TOP_CAT_DESCR,
    IC_POULTRY      = :NEW.IC_POULTRY,
    IC_FISH         = :NEW.IC_FISH,
    IC_MEAT         = :NEW.IC_MEAT,
    IC_FP           = :NEW.IC_FP,
    PG              = :NEW.PG
  WHERE C_ID = :OLD.C_ID;
END;
/