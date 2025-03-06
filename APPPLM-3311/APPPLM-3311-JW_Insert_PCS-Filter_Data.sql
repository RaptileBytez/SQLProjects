/*  Written by:   Jesco Wurm (ICP)
    Date:         9-12-2024
    Function:     Import current PCS filter configuration data  
                  (APPPLM-3311 - As a PCS user, I want the Filter functions work according the current Business Unit / Product Lines setup)
                  
*/


-- Adding the current configuration  
INSERT INTO T_PCS_CONFIG (C_ID, C_VERSION, C_LOCK, C_UIC, C_GIC, C_CRE_DAT, C_UPD_DAT, C_ACC_OGW, IC, INDICATOR, PROD_LINES)
    VALUES
        (1013507936, 2, 0, 3653, 100, SYSDATE, SYSDATE, 'ddr', 'Poultry', 'P', '100');
INSERT INTO T_PCS_CONFIG (C_ID, C_VERSION, C_LOCK, C_UIC, C_GIC, C_CRE_DAT, C_UPD_DAT, C_ACC_OGW, IC, INDICATOR, PROD_LINES)
    VALUES      
        (1537761268, 2, 0, 3653, 100, SYSDATE, SYSDATE, 'ddr', 'Fish', 'F', '040');
INSERT INTO T_PCS_CONFIG (C_ID, C_VERSION, C_LOCK, C_UIC, C_GIC, C_CRE_DAT, C_UPD_DAT, C_ACC_OGW, IC, INDICATOR, PROD_LINES)
    VALUES      
        (1953251272, 2, 0, 3653, 100, SYSDATE, SYSDATE, 'ddr', 'Meat', 'R', '060,090,150');
INSERT INTO T_PCS_CONFIG (C_ID, C_VERSION, C_LOCK, C_UIC, C_GIC, C_CRE_DAT, C_UPD_DAT, C_ACC_OGW, IC, INDICATOR, PROD_LINES)
    VALUES      
        (1273706951, 2, 0, 3653, 100, SYSDATE, SYSDATE, 'ddr', 'FP', 'T', '110,120');

-- Committing the insertion of data
COMMIT;