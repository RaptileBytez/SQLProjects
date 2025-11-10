/*
===============================================================================
Script Name: APPPLM-3905-JW_Update_T_PPO_PRIDEF.sql
===============================================================================
Description: Mass update of T_PPO_PRIDEF to change server references
             from DC1SR2063 to DC1SR1052 for specific OUTPUT_PARAMS paths. 
Author: Jesco Wurm (ICP)
Creation Date: 10-11-2025
Version: 1.0.0
Last Modified: 10-11-2025
Last Modified By: Jesco Wurm (ICP)
--------------------------------------------------------------------------------
Purpose: 
This script will 
    - Count the number of rows in T_PPO_PRIDEF where OUTPUT_PARAMS contains 
      references to server DC1SR2063 with paths including \PLMview\ but not \PLMViewCentral\.
    - Update those rows to change the server reference from DC1SR2063 to DC1SR1052.
    - Finally, it will count the number of rows updated to verify the changes.
--------------------------------------------------------------------------------  
Change History:
Date          Author                Version     Description
10-11-2025    Jesco Wurm (ICP)      1.0.0       Initial creation
===============================================================================
 */
SELECT COUNT(*) AS ROWS_AFFECTED
FROM T_PPO_PRIDEF
WHERE 
  REGEXP_LIKE(OUTPUT_PARAMS, 'DC1SR2063.*\\PLMview\\', 'i')
  AND NOT REGEXP_LIKE(OUTPUT_PARAMS, '\\PLMViewCentral\\', 'i');

UPDATE T_PPO_PRIDEF
SET OUTPUT_PARAMS = REGEXP_REPLACE(
    OUTPUT_PARAMS,
    -- pattern: searches for 'DC1SR2063' (case-insensitive) followed by '\PLMview\'
    '(DC1SR2063)(\\PLMview\\)',
    -- Replacement: 'DC1SR1052' followed by the found path (\2)
    'DC1SR1052\2',
    1,
    0,
    -- 'i': case-insensitive search for the pattern
    'i'
)
WHERE 
    -- Condition 1: Ensure the old server and the path (PLMview) exist (case-insensitive)
    REGEXP_LIKE(OUTPUT_PARAMS, 'DC1SR2063.*\\PLMview\\', 'i')
    -- Condition 2: Ensurem the permitted path (PLMViewCentral) does NOT exist (case-insensitive)
    AND NOT REGEXP_LIKE(OUTPUT_PARAMS, '\\PLMViewCentral\\', 'i');

commit;

SELECT COUNT(*) AS ROWS_UPDATED    
FROM T_PPO_PRIDEF
WHERE REGEXP_LIKE(OUTPUT_PARAMS, 'DC1SR1052.*\\PLMview\\', 'i');