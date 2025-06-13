/*
========================================================================
  Script Name: APPPLM-3574-JW_Update_Exports.sql
  Description: Update exports for PLMView servers in various locations.
 =========================================================================
 Author: Jesco Wurm (ICP)
 Creation Date: 12-06-2025
 Version: 1.0
 Last Modified: 12-06-2025 
 ------------------------------------------------------------------------------------
 Purpose:
  This script updates the PLMView server paths for various locations in the database.
  It replaces old server paths with new ones in the T_CFG_DAT and T_CITY_DAT tables,
  and handles a special case for the DC1 location in the SFS_PRC_CITY table.
 ------------------------------------------------------------------------------------
 Change History:
  - 12-06-2025: Initial creation by Jesco Wurm (ICP)
 */

-- Set up the environment
SET SERVEROUTPUT ON;
DECLARE
  TYPE t_loc IS RECORD (
    name         VARCHAR2(10),
    old_server   VARCHAR2(200),
    new_server   VARCHAR2(200)
  );
  TYPE t_loc_tab IS TABLE OF t_loc INDEX BY PLS_INTEGER;
  loc_tab t_loc_tab;

  -- Variables to hold the number of rows updated
  rows_updated_cfg  INTEGER := 0;
  rows_updated_city INTEGER := 0;
  rows_updated_prc  INTEGER := 0;
BEGIN
  -- Configuration
  -- Please ensure that the old and new server paths are correct and match your environment.
  -- The following old server paths are based on the PQE environment and my differ in other environments.

  loc_tab(1)  := t_loc('AAR', '\\aarsr0039\PLMView', '\\AARSR0044\PLMView');
  loc_tab(2)  := t_loc('BOX', '\\BOXSR0126\PLMView', '\\BOXSR0035\PLMView');
  loc_tab(3)  := t_loc('COL', '\\COLSR0024\PLMView', '\\COLSR0035\PLMView');
  loc_tab(4)  := t_loc('DON', '\\donsr0007\PLMView', '\\DONSR0035\PLMView');
  loc_tab(5)  := t_loc('DSM', '\\dsmsr0021\PLMView', '\\DSMSR0030\PLMView');
  loc_tab(6)  := t_loc('GAI', '\\gaisr0141\PLMView', '\\GAISR0035\PLMView');
  loc_tab(7)  := t_loc('GRB', '\\grbsr0127\PLMView', '\\GRBSR0035\PLMView');
  loc_tab(8)  := t_loc('GUP', '\\GUPSR0050\PLMview', '\\GUPSR0035\PLMView');
  loc_tab(9)  := t_loc('NRA', '\\nrasr0024\plmview_2', '\\NRASR0035\PLMView');
  loc_tab(10) := t_loc('PRC', '\\PRCSR0006\PLMView', '\\CPQSR0060\PLMView');
  loc_tab(11) := t_loc('STO', '\\STOSR0037\PLMView', '\\STOSR0035\PLMView');
  
  -- Important note: 
  -- Do not delete the \ or the Replace Function will also Update PLMViewCentral entries
  loc_tab(12) := t_loc('DC1', '\\dc1sr2063\PLMview\', '\\DC1SR1052\PLMView\'); --special case for DC1

  -- Loop through all locations
  FOR i IN 1..12 LOOP
    DBMS_OUTPUT.PUT_LINE('Updating location: ' || loc_tab(i).name);
    DBMS_OUTPUT.PUT_LINE('Old server: ' || loc_tab(i).old_server);
    DBMS_OUTPUT.PUT_LINE('New server: ' || loc_tab(i).new_server);

    IF i < 12 THEN
      -- Update T_CFG_DAT
      UPDATE T_CFG_DAT
      SET EDB_VALUE = loc_tab(i).new_server
      WHERE EDB_ID = 'SFS-DFS-CENTRAL-' || loc_tab(i).name
        AND EDB_VALUE = loc_tab(i).old_server;
      rows_updated_cfg := SQL%ROWCOUNT;

      -- Update T_CITY_DAT
      UPDATE T_CITY_DAT
      SET DFS_SERVER = loc_tab(i).new_server
      WHERE PHYSICAL_LOC = loc_tab(i).name
        AND DFS_SERVER = loc_tab(i).old_server;
      rows_updated_city := SQL%ROWCOUNT;

      DBMS_OUTPUT.PUT_LINE('Rows updated in T_CFG_DAT: ' || rows_updated_cfg);
      DBMS_OUTPUT.PUT_LINE('Rows updated in T_CITY_DAT: ' || rows_updated_city);
      DBMS_OUTPUT.PUT_LINE('---------------------');
    ELSE
      -- Special case: DC1 → REPLACE in SFS_PRC_CITY
      UPDATE SFS_PRC_CITY
      SET DSF_SERVER_REMOTE = REPLACE(DSF_SERVER_REMOTE, loc_tab(i).old_server, loc_tab(i).new_server)
      WHERE DSF_SERVER_REMOTE LIKE loc_tab(i).old_server || '%';
      rows_updated_prc := SQL%ROWCOUNT;

      DBMS_OUTPUT.PUT_LINE('Rows updated in SFS_PRC_CITY: ' || rows_updated_prc);
      DBMS_OUTPUT.PUT_LINE('---------------------');
    END IF;
  END LOOP;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('All updates completed and committed.');
END;
/

