/*
===========================================================================
Table Name: T_ERP_ECO_STAGING
===========================================================================
Description: Table to stage Item-Document-Relationships within an ECO
Author: Jesco Wurm (ICP)
Creation Date: 26-05-2025
Version: 1.0
Last Modified: 26-05-2025
Last Modified By: Jesco Wurm (ICP)
--------------------------------------------------------------------------------
Purpose: 
This script will create the table "T_ERP_ECO_STAGING" to stage Item-Document-Relationships
within an ECO process. This table is used to temporarily hold data before it is processed.
It includes various fields related to the parent item, child document, and their relationships.
--------------------------------------------------------------------------------  
Change History:
*/
CREATE TABLE T_ERP_ECO_STAGING (
  PAC_ID               NUMBER(6),
  ECO_NUMBER           VARCHAR2(40),
  PARENT_ITEM_CID      NUMBER(10),
  PARENT_ITEM_NUMBER   VARCHAR2(40),
  PARENT_ITEM_REVISION VARCHAR2(10),
  PARENT_ITEM_LEV_IND  NUMBER(10),
  CHILD_DOC_CID        NUMBER(10),
  CHILD_DOC_NUMBER     VARCHAR2(40),
  CHILD_DOC_REVISION   VARCHAR2(10),
  CHILD_DOC_LEV_IND    NUMBER(10),
  CHILD_DOC_TYPE       VARCHAR2(20),
  CHILD_DOC_SUBTYPE    VARCHAR2(10),
  CHILD_CAX_TYPE       VARCHAR2(20),
  CHILD_SHEET_NO       VARCHAR2(14),
  POS_NO               NUMBER(5),
  CHILD_PMT_STBN_ENG   VARCHAR2(20),
  CHILD_FREE_NAME      VARCHAR2(20),
  CHILD_STEP_ORG_REF   VARCHAR2(10),
  CHILD_STEP_NO_REF    VARCHAR2(10),
  ORIGIN_FLAG          VARCHAR2(10)
);