/*  Written by:   Jesco Wurm (ICP)
    Date:         3-4-2025
    Function:     Syncing ECO ITM INTGR STATUS to ECO BOM INTGR STATUS
    APPPLM-3684: As a Service MCE I don't want to be blocked using 'Q-Change ABC' when other BOM relations are still being handled by the integration to DPH
*/
CREATE OR REPLACE TRIGGER TRG_SYNC_INTGR_STATUS
AFTER UPDATE OF ECO_ITM_INTGR_JOB_STATUS ON T_ERP_ECO_ITM
FOR EACH ROW
BEGIN
  UPDATE T_ERP_ECO_BOM
  SET ECO_FAT_ITM_INTGR_STATUS = :NEW.ECO_ITM_INTGR_JOB_STATUS
  WHERE ECO_NUMBER = :NEW.ECO_NUMBER
    AND PARENT_ITEM_NUMBER = :NEW.ITEM_NUMBER;
END;
/