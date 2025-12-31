/*
===============================================================================
Script Name: APPPLM-3982-JW_PT1_Create_V_SFS_PCS_SOR.sql
===============================================================================
Description: Create view V_SFS_PCS_SOR for table T_SFS_PCS_SOR 
Author: Jesco Wurm (ICP)
Creation Date: 22-12-2025
Version: 1.0.0
Last Modified: 22-12-2025
Last Modified By: Jesco Wurm (ICP)
--------------------------------------------------------------------------------
Purpose: 
This script will 
    - Create or replace the view V_SFS_PCS_SOR selecting all columns from T_SFS_PCS_SOR.
--------------------------------------------------------------------------------  
Change History:
Date          Author                Version     Description
22-12-2025    Jesco Wurm (ICP)      1.0.0       Initial creation
===============================================================================
 */
CREATE OR REPLACE VIEW V_SFS_PCS_SOR AS
SELECT
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
  PG,
  VIR_COL_IC
FROM T_SFS_PCS_SOR;