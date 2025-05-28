/*
===========================================================================
Table Name: T_ERP_ECO_IDR
===========================================================================
Description: Table for Item-Document-Relationships with an ECO
Author: Jesco Wurm (ICP)
Creation Date: 21-05-2025
Version: 1.0
Last Modified: 21-05-2025
Last Modified By: Jesco Wurm (ICP)
--------------------------------------------------------------------------------
Purpose: 
This script will drop the column "CHILD_NFILE_FORMAT" from the table "T_ERP_ECO_IDR"
as it is not needed anymore. The column was used to store the file format of the child
document in the ECO process.
--------------------------------------------------------------------------------  
Change History:
*/
ALTER TABLE "T_ERP_ECO_IDR" 
DROP COLUMN "CHILD_NFILE_FORMAT" CASCADE CONSTRAINTS;