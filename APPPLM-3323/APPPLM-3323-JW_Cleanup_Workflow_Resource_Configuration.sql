/*  Written by:   Jesco Wurm (ICP)
    Date:         26-11-2024
    Function:     Delete records from the Workflow Resource Configuration 
                  (APPPLM-3323 - As a PCB PLM user in Boxmeer I want the Electrical&Controls ECR to be handled by the Machine Code Product Coordinators, similarly as for Engineering ECR)
                  
*/


-- Determine the entries to be deleted
SELECT * FROM SFS_WFL_RCON
WHERE (LOC_ID = 'BXM'  OR LOC_ID = 'GSV' -- OR LOC_ID = 'NRA'
) AND RES_DEPT = 'ELECTRICAL AND CONTROLS';

-- Delete those records
DELETE FROM SFS_WFL_RCON
WHERE (LOC_ID = 'BXM'  OR LOC_ID = 'GSV' -- OR LOC_ID = 'NRA'
) AND RES_DEPT = 'ELECTRICAL AND CONTROLS';

commit;