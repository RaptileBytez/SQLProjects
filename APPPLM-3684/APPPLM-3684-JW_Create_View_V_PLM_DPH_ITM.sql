/*
===============================================================================
View: V_PLM_DPH_BOM
===============================================================================
Description: View for T_ERP_ECO_BOM with dynamic Service Fields
Author: Jesco Wurm (ICP)
Creation Date: 11-04-2025
Version: 1.0
Last Modified: 15-04-2025
Last Modified By: Jesco Wurm (ICP)
--------------------------------------------------------------------------------
Purpose: 
This view is used to retrieve the Interfaced BOM data from T_ERP_ECO_BOM and
join it with the most recent service fields from T_MASTER_STR.
This is necessary to minimize the amount of blocks in Agile e6 and ensure that
DPH is able to retrieve up-to-date data from the database.
--------------------------------------------------------------------------------  
Change History:
- 11-04-2025: Initial creation of the view for 
APPPLM-3684 - As a Service MCE I don't want to be blocked using 
'Q-Change ABC' when other BOM relations are still being handled 
by the integration to DPH.
- 15-04-2025: Added GRANTs for the view to PLM_QS_INTGR_READWRITE_ROLE and PLM_QS_READ_ONLY_ROLE
===============================================================================
 */
CREATE OR REPLACE EDITIONABLE VIEW
    "V_PLM_DPH_BOM" (
        "BOM_CID",
        "ECO_NUMBER",
        "PARENT_ITEM_NUMBER",
        "PARENT_ITEM_REVISION",
        "PARENT_ITEM_TYPE",
        "PARENT_SUBTYPE",
        "CHILD_ITEM_NUMBER",
        "CHILD_ITEM_REVISION",
        "CHILD_SUBTYPE",
        "CHILD_SAP_ITM_CAT",
        "ECO_FAT_ITM_INTGR_STATUS",
        "POS_NO",
        "QUANTITY",
        "CHILD_UNIT_OF_MEASURE",
        "E_CODE",
        "BRDT",
        "LENG",
        "REMARKS",
        "SPARE",
        "SEIM",
        "SEIM_1",
        "SEIM_QUANT",
        "SFS_IDSERVICE",
        "CPP_CRIT",
        "CPP_RQ",
        "CPP_USAGE"
    ) DEFAULT COLLATION "USING_NLS_COMP" AS
SELECT
    ECO_BOM.BOM_CID,
    ECO_BOM.ECO_NUMBER,
    ECO_BOM.PARENT_ITEM_NUMBER,
    ECO_BOM.PARENT_ITEM_REVISION,
    ECO_BOM.PARENT_ITEM_TYPE,
    ECO_BOM.PARENT_SUBTYPE,
    ECO_BOM.CHILD_ITEM_NUMBER,
    ECO_BOM.CHILD_ITEM_REVISION,
    ECO_BOM.CHILD_SUBTYPE,
    ECO_BOM.CHILD_SAP_ITM_CAT,
    ECO_BOM.ECO_FAT_ITM_INTGR_STATUS,
    ECO_BOM.POS_NO,
    ECO_BOM.QUANTITY,
    ECO_BOM.CHILD_UNIT_OF_MEASURE,
    ECO_BOM.E_CODE,
    ECO_BOM.BRDT,
    ECO_BOM.LENG,
    ECO_BOM.REMARKS,
    STR.SPARE,
    STR.SEIM,
    STR.SEIM_1,
    STR.SEIM_QUANT,
    STR.SFS_IDSERVICE,
    STR.CPP_CRIT,
    STR.CPP_RQ,
    STR.CPP_USAGE
FROM
    T_ERP_ECO_BOM ECO_BOM
    INNER JOIN T_MASTER_STR STR ON STR.C_ID = ECO_BOM.BOM_CID;

-- Granting select privileges on the view to the required roles
GRANT
SELECT
    ON V_PLM_DPH_BOM TO "PLM_QS_INTGR_READWRITE_ROLE";

GRANT
SELECT
    ON V_PLM_DPH_BOM TO "PLM_QS_READ_ONLY_ROLE";