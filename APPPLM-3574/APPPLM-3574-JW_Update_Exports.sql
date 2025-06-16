/*
========================================================================
  Script Name: APPPLM-3574-JW_Update_Exports.sql
  Description: Update exports for PLMView servers in various locations.
 =========================================================================
 Author: Jesco Wurm (ICP)
 Creation Date: 12-06-2025
 Version: 2.0
 Last Modified: 16-06-2025 
 ------------------------------------------------------------------------------------
 Purpose:
  This script replaces all old DFS server paths with new ones across
  T_CFG_DAT, T_CITY_DAT, and SFS_PRC_CITY tables, regardless of location.
  The only exception is: SFS-DFS-CENTRAL must retain the value
  '\\dc1sr2063\PLMviewCentral'.
 ------------------------------------------------------------------------------------
 Change History:
  - 12-06-2025: Initial creation by Jesco Wurm (ICP)
  - 16-06-2025: Version 2.0 by Jesco Wurm (ICP): Changed logic
 */

-- Set up the environment
SET SERVEROUTPUT ON;
DECLARE
  TYPE t_loc IS RECORD (
    old_server   VARCHAR2(400),
    new_server   VARCHAR2(400)
  );
  TYPE t_loc_tab IS TABLE OF t_loc INDEX BY PLS_INTEGER;
  loc_tab t_loc_tab;

  rows_updated_cfg  INTEGER := 0;
  rows_updated_city INTEGER := 0;
  rows_updated_prc  INTEGER := 0;
BEGIN
  -- Configuration: old servers → new servers
  loc_tab(1)  := t_loc('\\aarsr0039\PLMView',       '\\AARSR0044\PLMView');
  loc_tab(2)  := t_loc('\\BOXSR0126\PLMView',       '\\BOXSR0035\PLMView');
  loc_tab(3)  := t_loc('\\COLSR0024\PLMView',       '\\COLSR0035\PLMView');
  loc_tab(4)  := t_loc('\\donsr0007\PLMView',       '\\DONSR0035\PLMView');
  loc_tab(5)  := t_loc('\\dsmsr0021\PLMView',       '\\DSMSR0030\PLMView');
  loc_tab(6)  := t_loc('\\gaisr0141\PLMView',       '\\GAISR0035\PLMView');
  loc_tab(7)  := t_loc('\\grbsr0127\PLMView',       '\\GRBSR0035\PLMView');
  loc_tab(8)  := t_loc('\\GUPSR0050\PLMview',       '\\GUPSR0035\PLMView');
  loc_tab(9)  := t_loc('\\nrasr0024\plmview_2',     '\\NRASR0035\PLMView');
  loc_tab(10) := t_loc('\\PRCSR0006\PLMView',       '\\CPQSR0060\PLMView');
  loc_tab(11) := t_loc('\\STOSR0037\PLMView',       '\\STOSR0035\PLMView');
  -- Important note: Keep the backslash at the end of the path
  -- to ensure correct path replacement in the database.
  loc_tab(12) := t_loc('\\dc1sr2063\PLMview\',      '\\DC1SR1052\PLMView\');

  -- Loop over all server mappings
  FOR i IN 1..loc_tab.COUNT LOOP
    DBMS_OUTPUT.PUT_LINE('Replacing: ' || loc_tab(i).old_server || ' → ' || loc_tab(i).new_server);

    -- Update T_CFG_DAT abut keep SFS-DFS-CENTRAL with its specific value
    UPDATE T_CFG_DAT
    SET EDB_VALUE = loc_tab(i).new_server
    WHERE EDB_VALUE = loc_tab(i).old_server
      AND NOT (
        EDB_ID = 'SFS-DFS-CENTRAL'
        AND EDB_VALUE = '\\dc1sr2063\PLMviewCentral'
      );
    rows_updated_cfg := SQL%ROWCOUNT;

    -- Update T_CITY_DAT 
    UPDATE T_CITY_DAT
    SET DFS_SERVER = loc_tab(i).new_server
    WHERE DFS_SERVER = loc_tab(i).old_server;
    rows_updated_city := SQL%ROWCOUNT;

    -- Update SFS_PRC_CITY 
    UPDATE SFS_PRC_CITY
    SET DSF_SERVER_REMOTE = REPLACE(DSF_SERVER_REMOTE, loc_tab(i).old_server, loc_tab(i).new_server)
    WHERE DSF_SERVER_REMOTE LIKE loc_tab(i).old_server || '%';
    rows_updated_prc := SQL%ROWCOUNT;

    DBMS_OUTPUT.PUT_LINE('T_CFG_DAT:      ' || rows_updated_cfg || ' rows updated');
    DBMS_OUTPUT.PUT_LINE('T_CITY_DAT:     ' || rows_updated_city || ' rows updated');
    DBMS_OUTPUT.PUT_LINE('SFS_PRC_CITY:   ' || rows_updated_prc || ' rows updated');
    DBMS_OUTPUT.PUT_LINE('----------------------------');
  END LOOP;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('All updates completed and committed.');
END;
/