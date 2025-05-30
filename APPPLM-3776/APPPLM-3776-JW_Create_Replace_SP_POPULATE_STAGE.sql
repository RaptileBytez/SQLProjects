/*
===========================================================================
  PROCEDURE: SP_POPULATE_IDR
===========================================================================
Description:    Stored procedure that, for a given ECO, finds all 
                Document–Item relationships involving any Document or Item in the
                change (directly or by association), flags each as 
                direct (both sides in the ECO) or inferred (only one side in the ECO),
                eliminates duplicates, and writes the result to the staging table 
                T_ERP_ECO_STAGING.
Author:         Jesco Wurm (ICP)
Creation Date:  26-05-2025
Version:        1.0
Last Modified:  26-05-2025
Last Modified By: Jesco Wurm (ICP)
--------------------------------------------------------------------------------
  PURPOSE
    Populate staging table T_ERP_ECO_STAGING with all Item–Document
    relationships for a given ECO, marking each as ‘direct’ or ‘inferred’.
    Ensures each pair appears exactly once.

  PARAMETER
    p_eco_number   VARCHAR2
      The external ECO identifier (ELEM_ID) used to look up PAC_ID.

  LOGIC OVERVIEW
    1) Lookup PAC_ID from T_EWO_DAT by p_eco_number.
    2) Delete any existing rows in T_ERP_ECO_STAGING for that ECO_NUMBER.
    3) Insert all “Document→Item” relations:
       • For every Document in V_PAC_OBJ (C_ENTNAM='EDB-DOCUMENT'):
         – Join through T_MASTER_DOC to find all related Items.
         – If the Item is also in V_PAC_OBJ for this PAC_ID → origin_flag = 'direct'
         – Otherwise → origin_flag = 'inferred'
    4) Insert all “Item→Document” relations not already covered:
       • For every Item in V_PAC_OBJ (C_ENTNAM='EDB-ARTICLE'):
         – Join through T_MASTER_DOC to find all related Documents.
         – Only include those Documents that are NOT in V_PAC_OBJ for this PAC_ID →
           these are inferred.
       • origin_flag for these rows is always 'inferred'.
    5) Commit all changes.

  REQUIREMENTS MET
    a) Direct ECO pairs (both Item and Document listed) are captured and
       flagged ‘direct’.
    b) If only the Item is in the ECO set, all its Documents are captured →
       flagged ‘inferred’.
    c) If only the Document is in the ECO set, all its Items are captured →
       flagged ‘inferred’.
    d) Duplicates of direct pairs are prevented by excluding Documents that
       have already been handled in the first step when inserting Item→Document.

 */
CREATE OR REPLACE PROCEDURE SP_POPULATE_STAGE (
  p_eco_number IN VARCHAR2
)
IS
  v_pac_id NUMBER;
BEGIN
  ----------------------------------------------------------------
  -- 1) PAC_ID Lookup
  ----------------------------------------------------------------
  SELECT PAC_REF INTO v_pac_id
  FROM T_EWO_DAT
  WHERE ELEM_ID = p_eco_number;

  ----------------------------------------------------------------
  -- 2) Clear Staging-Tabelle from previous runs
  ----------------------------------------------------------------
  DELETE FROM T_ERP_ECO_STAGING
  WHERE ECO_NUMBER = p_eco_number;

  ----------------------------------------------------------------
  -- 3) Document → Item
  ----------------------------------------------------------------
  INSERT INTO T_ERP_ECO_STAGING (
    PAC_ID,
    ECO_NUMBER,
    PARENT_ITEM_CID,
    PARENT_ITEM_NUMBER,
    PARENT_ITEM_REVISION,
    PARENT_ITEM_LEV_IND,
    CHILD_DOC_CID,
    CHILD_DOC_NUMBER,
    CHILD_DOC_REVISION,
    CHILD_DOC_LEV_IND,
    CHILD_DOC_TYPE,
    CHILD_DOC_SUBTYPE,
    CHILD_CAX_TYPE,
    CHILD_SHEET_NO,
    POS_NO,
    CHILD_PMT_STBN_ENG,
    CHILD_FREE_NAME,
    CHILD_STEP_ORG_REF,
    CHILD_STEP_NO_REF,
    ORIGIN_FLAG,
    RELATION_TYPE
  )
  SELECT
    v_pac_id,
    p_eco_number,
    prt.C_ID,
    prt.PART_ID,
    prt.PART_VERSION,
    prt.LEV_IND,
    ad.C_ID,
    ad.DOCUMENT_ID,
    ad.DOC_VERSION,
    ad.LEV_IND,
    ad.DOC_TYPE,
    ad.DOC_SUBTYPE,
    ad.CAX_TYPE,
    ad.SHEET_NO,
    md.POS_NO,
    ad.PMT_STBN_ENG,
    ad.FREE_NAME,
    ad.STEP_ORG_REF,
    ad.STEP_NO_REF,
    CASE 
      WHEN ao_item.OBJ_CID IS NOT NULL THEN 'direct' 
      ELSE 'inferred' 
    END,
    'Document→Item'
  FROM V_PAC_OBJ ao_doc
  JOIN T_DOC_DAT ad 
    ON ao_doc.OBJ_CID = ad.C_ID AND ao_doc.C_ENTNAM = 'EDB-DOCUMENT'
  JOIN T_MASTER_DOC md 
    ON md.C_ID_2 = ad.C_ID
  JOIN T_MASTER_DAT prt 
    ON prt.C_ID = md.C_ID_1
  LEFT JOIN V_PAC_OBJ ao_item 
    ON ao_item.OBJ_CID = prt.C_ID AND ao_item.PAC_ID = v_pac_id
  WHERE ao_doc.PAC_ID = v_pac_id;

  ----------------------------------------------------------------
  -- 4) Item → Document (only inferred)
  ----------------------------------------------------------------
  INSERT INTO T_ERP_ECO_STAGING (
    PAC_ID,
    ECO_NUMBER,
    PARENT_ITEM_CID,
    PARENT_ITEM_NUMBER,
    PARENT_ITEM_REVISION,
    PARENT_ITEM_LEV_IND,
    CHILD_DOC_CID,
    CHILD_DOC_NUMBER,
    CHILD_DOC_REVISION,
    CHILD_DOC_LEV_IND,
    CHILD_DOC_TYPE,
    CHILD_DOC_SUBTYPE,
    CHILD_CAX_TYPE,
    CHILD_SHEET_NO,
    POS_NO,
    CHILD_PMT_STBN_ENG,
    CHILD_FREE_NAME,
    CHILD_STEP_ORG_REF,
    CHILD_STEP_NO_REF,
    ORIGIN_FLAG,
    RELATION_TYPE
  )
  SELECT
    v_pac_id,
    p_eco_number,
    ai.C_ID,
    ai.PART_ID,
    ai.PART_VERSION,
    ai.LEV_IND,
    dd.C_ID,
    dd.DOCUMENT_ID,
    dd.DOC_VERSION,
    dd.LEV_IND,
    dd.DOC_TYPE,
    dd.DOC_SUBTYPE,
    dd.CAX_TYPE,
    dd.SHEET_NO,
    md.POS_NO,
    dd.PMT_STBN_ENG,
    dd.FREE_NAME,
    dd.STEP_ORG_REF,
    dd.STEP_NO_REF,
    'inferred',
    'Item→Document'
  FROM V_PAC_OBJ ao_item
  JOIN T_MASTER_DAT ai 
    ON ao_item.OBJ_CID = ai.C_ID AND ao_item.C_ENTNAM = 'EDB-ARTICLE'
  JOIN T_MASTER_DOC md 
    ON md.C_ID_1 = ai.C_ID
  JOIN T_DOC_DAT dd 
    ON dd.C_ID = md.C_ID_2
  LEFT JOIN V_PAC_OBJ ao_doc 
    ON ao_doc.OBJ_CID = dd.C_ID AND ao_doc.PAC_ID = v_pac_id
  WHERE ao_item.PAC_ID = v_pac_id
    AND ao_doc.OBJ_CID IS NULL;

  ----------------------------------------------------------------
  -- 5) Commit
  ----------------------------------------------------------------
  COMMIT;
END;
/