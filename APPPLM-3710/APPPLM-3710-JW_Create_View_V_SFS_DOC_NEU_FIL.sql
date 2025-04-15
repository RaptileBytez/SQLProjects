/*
===============================================================================
View: V_SFS_DOC_NEU_FIL
===============================================================================
Description: View for T_ERP_ECO_BOM with dynamic Service Fields
Author: Jesco Wurm (ICP)
Creation Date: 15-04-2025
Version: 1.0
Last Modified: 15-04-2025
Last Modified By: Jesco Wurm (ICP)
--------------------------------------------------------------------------------
Purpose: 
This view is used to retrieve all relevant doucument and file data for interfacing
the view files towards DPH.
--------------------------------------------------------------------------------  
Change History:
- 15-04-2025: Initial creation of the view for 
APPPLM-3710 - As a PLM Administrator, we would like to have
a DB View for interfacing physical view files towards DPH
===============================================================================
 */
CREATE OR REPLACE FORCE EDITIONABLE VIEW
    "V_SFS_DOC_NEU_FIL" (
        "DOC_CID",
        "DOCUMENT_ID",
        "DOC_VERSION",
        "SHEET_NO",
        "FILE_NAME",
        "STORE_DISCPATH",
        "ORG_NAME",
        "FILE_FORMAT",
        "MODIFY_DATE",
        "STEP_CRE_SYSTEM",
        "FILE_STATUS",
        "SITE",
        "DOC_TYPE",
        "LEV_IND",
        "LOC_ID",
        "FORMAT",
        "LOCK",
        "NUMBER_FILES"
    ) DEFAULT COLLATION "USING_NLS_COMP" AS
SELECT
    "DOC_CID",
    "DOCUMENT_ID",
    "DOC_VERSION",
    "SHEET_NO",
    "FILE_NAME",
    "STORE_DISCPATH",
    "ORG_NAME",
    "FILE_FORMAT",
    "MODIFY_DATE",
    "STEP_CRE_SYSTEM",
    "FILE_STATUS",
    "SITE",
    "DOC_TYPE",
    "LEV_IND",
    "LOC_ID",
    "FORMAT",
    "LOCK",
    (
        SELECT
            SFS_NUMBER_VIEWABLE_FILES (DOCUMENT_ID, NVL(DOC_VERSION, '-'))
        FROM
            dual
    ) AS "NUMBER_FILES"
FROM
    (
        SELECT
            doc.C_ID,
            fs.FILE_NAME,
            sa.STORE_DISCPATH,
            fil.ORG_NAME,
            fil.FILE_FORMAT,
            fil.MODIFY_DATE,
            fil.STEP_CRE_SYSTEM,
            fs.FILE_STATUS,
            sa.SITE,
            doc.DOCUMENT_ID,
            doc.SHEET_NO,
            doc.DOC_TYPE,
            doc.LEV_IND,
            doc.LOC_ID,
            doc.FORMAT,
            COUNT(T_PMT_DOC_LOC.DOC_CID) AS "LOCK",
            doc.DOC_VERSION,
            doc.C_ID "DOC_CID"
        FROM
            T_DOC_FIL df,
            T_FILE_DAT fil,
            T_FIL_STORE fs,
            T_STORE_AREA sa,
            T_DOC_DAT doc,
            T_PMT_DOC_LOC
        WHERE
            df.C_ID_1 = doc.C_ID
            AND fil.C_ID = df.C_ID_2
            AND fs.C_ID_1 = df.C_ID_2
            AND sa.C_ID = fs.C_ID_2
            --AND doc.LEV_IND < 250
            --AND doc.LEV_IND <> 160
            --AND doc.LEV_IND <> 165
            AND (
                (
                    doc.DOC_TYPE = 'ACAD'
                    AND doc.CAX_TYPE = 'DRW1'
                )
                OR doc.DOC_TYPE = 'EPLANP'
                OR doc.DOC_TYPE = 'PROED'
                OR doc.DOC_TYPE = 'INVDRW'
                OR doc.DOC_TYPE = 'GAMVIEW'
                OR doc.DOC_TYPE = 'SLDDRW'
                OR doc.DOC_TYPE = 'SCAN'
                OR doc.DOC_TYPE = '3DVIEW'
                OR doc.DOC_TYPE = 'SOF'
                OR doc.DOC_TYPE = 'PCB'
            )
            AND (
                fil.FILE_FORMAT = 'HPGL'
                OR fil.FILE_FORMAT = 'PDF'
                OR fil.FILE_FORMAT = 'DXF'
                OR fil.FILE_FORMAT = 'DXFW'
                OR fil.FILE_FORMAT = 'ZIP'
                OR fil.FILE_FORMAT = 'CFG'
            )
            AND T_PMT_DOC_LOC.DOCUMENT_ID (+) = doc.DOCUMENT_ID
            AND T_PMT_DOC_LOC.DOC_VERSION (+) = doc.DOC_VERSION
        GROUP BY
            doc.DOCUMENT_ID,
            doc.DOC_VERSION,
            doc.SHEET_NO,
            fs.FILE_NAME,
            sa.STORE_DISCPATH,
            fil.ORG_NAME,
            fil.FILE_FORMAT,
            fil.MODIFY_DATE,
            fil.STEP_CRE_SYSTEM,
            fs.FILE_STATUS,
            sa.SITE,
            doc.DOC_TYPE,
            doc.LEV_IND,
            doc.LOC_ID,
            doc.FORMAT,
            doc.C_ID
        WITH
            READ ONLY
    ) rec
/*
ORDER BY
    rec.document_id ASC,
    rec.doc_version ASC nulls FIRST*/
    ;

GRANT
SELECT
    ON "V_SFS_DOC_NEU_FIL" TO "PLM_QS_READ_ONLY_ROLE";

GRANT
SELECT
    ON "V_SFS_DOC_NEU_FIL" TO "PLM_QS_INTGR_READWRITE_ROLE";