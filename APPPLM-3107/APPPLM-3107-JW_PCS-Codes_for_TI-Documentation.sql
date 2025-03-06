/*  Written by:   Harald Weber (XPLM)
    Date:         06-11-2019
    Function:     Create query for TI documentation list
                  JIRA-APPPLM-504
    Changed by:   Harald Weber (XPLM)
    Date:         26-11-2019/17-01-2020
    Function:     Advanced query for TI documentation list
                  Rebuild by using Global Temporary Table (GTT)
                  JIRA-APPPLM-607 + 617
	Changed by:   Stephan Diedershagen
    Date:         28-09-2023
    Function:     Added XXX product line to the script
	              JIRA-APPPLM-2678
	Changed by:   Jesco Wurm
    Date:         07-08-2024
    Function:     Introduction of PCS-Codes to the report
	              JIRA-APPPLM-3014
*/

WHENEVER OSERROR EXIT OSCODE
WHENEVER SQLERROR EXIT SQL.SQLCODE

SET NEWPAGE 0
SET PAGESIZE 0
SET LINESIZE 500
SET FEEDBACK OFF
SET HEADING OFF
SET VERIFY OFF
SET TRIMOUT ON
SET TRIMSPOOL ON
SET ECHO OFF

COLUMN TODAY NOPRINT NEW_VALUE DATEVAR
SELECT
 TO_CHAR(SYSDATE, 'YYYY-MM-DD') TODAY
FROM
 DUAL
;

SPOOL &1\TI-Documentation-&DATEVAR..csv;
--SPOOL C:\Temp\TI-Documentation-&DATEVAR..csv;
--SPOOL W:\PLMView\Reports\TI-Documentation\TI-Documentation-&DATEVAR..csv;
--SPOOL \\dc1sr2063\PLMView\BOX\Reports\TI-Documentation\TI-Documentation-&DATEVAR..csv;
--SPOOL \\dc1sr2063\PLMView\BOX\DEV\Reports\TI-Documentation\TI-Documentation-&DATEVAR..csv;

-- empty and remove possible existing global temporary tables
BEGIN
 EXECUTE IMMEDIATE 'TRUNCATE TABLE T_TI_DOC_REP';
 EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN RAISE;
  END IF;
END;
/
BEGIN
 EXECUTE IMMEDIATE 'DROP TABLE T_TI_DOC_REP';
 EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN RAISE;
  END IF;
END;
/
BEGIN
 EXECUTE IMMEDIATE 'TRUNCATE TABLE T_TI_REP_PCS';
 EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN RAISE;
  END IF;
END;
/
BEGIN
 EXECUTE IMMEDIATE 'DROP TABLE T_TI_REP_PCS';
 EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN RAISE;
  END IF;
END;
/

-- create new global temporary tables
CREATE GLOBAL TEMPORARY TABLE
 T_TI_DOC_REP
(
  ARTCID NUMBER(10)
 ,PART_ID VARCHAR2(40 CHAR)
 ,MCODE VARCHAR2(6 CHAR)
 ,MNAME_COM VARCHAR2(40 CHAR)
 ,FREE_NAME VARCHAR2(20 CHAR)
 ,DOC_LIST1 VARCHAR2(2000 CHAR)
 ,DOC_LIST2 VARCHAR2(2000 CHAR)
 ,DOC_LIST3 VARCHAR2(2000 CHAR)
 ,DOC_LIST4 VARCHAR2(2000 CHAR)
 ,LEV_IND NUMBER(10)
 ,UITVOERING VARCHAR2 (15 CHAR)
 ,SEL_FLAG NUMBER(10)
 ,ADTE VARCHAR(10)
 ,LOC VARCHAR(3)
 ,PLANT_ID VARCHAR(3)
 ,PCS_CODE VARCHAR2 (30 CHAR)
)
ON COMMIT PRESERVE ROWS;

--create new temporary table to store all C_IDs with a PCS-Class Code
CREATE GLOBAL TEMPORARY TABLE
 T_TI_REP_PCS
(
  ARTCID NUMBER(10)
  ,CLASS_CODE VARCHAR2 (30 CHAR)
)
ON COMMIT PRESERVE ROWS;

--fill the table with all ARTCIDs and PCS-codes
MERGE INTO
 T_TI_REP_PCS GTPCS
USING
 (
  SELECT DISTINCT 
    ga.C_ID_2 AS ARTCID, grp.CLASS_CODE
  FROM
    T_GRP_ART ga
  JOIN
    T_GROUP_DAT grp ON ga.C_ID_1 = grp.C_ID
  WHERE
    grp.CLASS_CODE LIKE 'PCS%' 
 ) PCS_SEL
ON
 (
  GTPCS.ARTCID = PCS_SEL.ARTCID
 )
WHEN NOT MATCHED THEN
 INSERT
  (
    ARTCID
    ,CLASS_CODE
  )
 VALUES
  (
    PCS_SEL.ARTCID
    ,PCS_SEL.CLASS_CODE
  )
;
COMMIT;



-- write all versions of items with status 250 to a MCODE in the global temporary table
-- item no. is referred to in Ref.no. 
-- flag is not set
MERGE INTO
 T_TI_DOC_REP GTT
USING
 (
  SELECT
    ART.C_ID,
    ART.PART_ID,
    ART.MCODE,
    ART.FREE_NAME,
    ART.LEV_IND,
    ART.UITVOERING,
    to_char(ART.ADTE, 'dd-mm-yyyy') ADTE,
    ART.LOC_ID,
    ART.PLANT_ID
  FROM
    T_MASTER_DAT ART
  WHERE
    ART.ART_TYP  IN ('V','I')
    AND
        ART.PLANT_ID IN ('P','T','R','100','120','090','140','XXX')
    AND
        (ART.LOC_ID   =  'BXM' OR
        ART.LOC_ID   =  'GSV' OR
        ART.LOC_ID   =  'DSM' OR
        ART.LOC_ID   =  'BAU')
    AND
        ART.CUR_FLAG =  'y'
    AND
        ART.LEV_IND  =  250
    AND
        ART.PART_ID  NOT LIKE '%AE'
    AND
        ART.PART_ID  in 
        (
        SELECT
            A.BINR
        FROM
            T_MASTER_DAT A
        WHERE
            A.ART_TYP  IN ('V','I')
        AND
            A.PLANT_ID IN ('P','T','R','100','120','090','140','XXX')
        AND
            A.MCODE    =  ART.MCODE
        AND
            A.CUR_FLAG =  'y'
        AND
            A.PART_ID  NOT LIKE '%AE'
    )
 ) SEL
ON
 (
  GTT.ARTCID = SEL.C_ID
 )
WHEN NOT MATCHED THEN
 INSERT
  (
     ARTCID
    ,PART_ID
    ,MCODE
    ,FREE_NAME
    ,LEV_IND
    ,UITVOERING
    ,SEL_FLAG
    ,ADTE
  )
 VALUES
  (
    SEL.C_ID
   ,SEL.PART_ID
   ,SEL.MCODE
   ,SEL.FREE_NAME
   ,SEL.LEV_IND
   ,SEL.UITVOERING
   ,0
   ,SEL.ADTE
  )
;
COMMIT;

-- update flag for the latest version of these items in the global temporary table
UPDATE
 T_TI_DOC_REP GTT
SET
 SEL_FLAG = 1
WHERE
 ARTCID IN
  (
   SELECT
    GTT1.ARTCID
   FROM
    T_TI_DOC_REP GTT1
   WHERE
    (GTT1.MCODE, TO_NUMBER(GTT1.UITVOERING))
   IN
   (
    SELECT
     GTT2.MCODE,
     MAX(TO_NUMBER(GTT2.UITVOERING)) 
    FROM T_TI_DOC_REP GTT2
    GROUP BY GTT2.MCODE
   )
  )
;
COMMIT;

-- update flag for the latest version of these items in the global temporary table
UPDATE
 T_TI_DOC_REP GTT
SET
 SEL_FLAG = 1
WHERE
 ARTCID IN
  (
   SELECT
    GTT1.ARTCID
   FROM
    T_TI_DOC_REP GTT1
   WHERE
    (GTT1.MCODE, TO_NUMBER(GTT1.UITVOERING))
   IN
   (
    SELECT
     GTT2.MCODE,
     MAX(TO_NUMBER(GTT2.UITVOERING)) 
    FROM T_TI_DOC_REP GTT2
    GROUP BY GTT2.MCODE
   )
  )
;
COMMIT;

-- write all versions of items with status 250 to a MCODE in the global temporary table
-- item no. is NOT referred to in Ref.no. 
-- flag is set
MERGE INTO
 T_TI_DOC_REP GTT
USING
 (
  SELECT
    ART.C_ID
   ,ART.PART_ID
   ,ART.MCODE
   ,ART.FREE_NAME
   ,ART.LEV_IND
   ,ART.UITVOERING
   ,to_char(ART.ADTE, 'dd-mm-yyyy') ADTE
   ,ART.LOC_ID
   ,ART.PLANT_ID
  FROM
    T_MASTER_DAT ART
  WHERE
   ART.ART_TYP  IN ('V','I')
  AND
   ART.PLANT_ID IN ('P','T','R','100','120','090','140','XXX')
  AND
   (ART.LOC_ID   =  'BXM' OR
    ART.LOC_ID   =  'GSV' OR
	ART.LOC_ID   =  'DSM' OR
    ART.LOC_ID   =  'BAU')
  AND
   ART.CUR_FLAG =  'y'
  AND
   ART.LEV_IND  =  250
  AND
   ART.PART_ID  NOT LIKE '%AE'
  AND
   ART.PART_ID  NOT IN 
    (
     SELECT
      A.BINR
     FROM
      T_MASTER_DAT A
     WHERE
      A.ART_TYP  IN ('V','I')
     AND
      A.PLANT_ID IN ('P','T','R','100','120','090','140','XXX')
     AND
      A.MCODE    =  ART.MCODE
     AND
      A.CUR_FLAG =  'y'
     AND
      A.PART_ID  NOT LIKE '%AE'
     AND
      A.BINR IS NOT NULL
    )
 ) SEL
ON
 (
  GTT.ARTCID = SEL.C_ID
 )
WHEN NOT MATCHED THEN
 INSERT
  (
     ARTCID
    ,PART_ID
    ,MCODE
    ,FREE_NAME
    ,LEV_IND
    ,UITVOERING
    ,SEL_FLAG
    ,ADTE
    ,LOC
    ,PLANT_ID
  )
 VALUES
  (
    SEL.C_ID
   ,SEL.PART_ID
   ,SEL.MCODE
   ,SEL.FREE_NAME
   ,SEL.LEV_IND
   ,SEL.UITVOERING
   ,1
   ,SEL.ADTE
   ,SEL.LOC_ID
   ,SEL.PLANT_ID
  )
;
COMMIT;

-- write all versions of items with status <250 to a MCODE in the global temporary table
-- flag is set
MERGE INTO
 T_TI_DOC_REP GTT
USING
 (
  SELECT
    ART.C_ID
   ,ART.PART_ID
   ,ART.MCODE
   ,ART.FREE_NAME
   ,ART.LEV_IND
   ,ART.UITVOERING
   ,to_char(ART.ADTE, 'dd-mm-yyyy') ADTE
   ,ART.LOC_ID
   ,ART.PLANT_ID
  FROM
    T_MASTER_DAT ART
  WHERE
   ART.ART_TYP  IN ('V','I')
  AND
   ART.PLANT_ID IN ('P','T','R','100','120','090','140','XXX')
  AND
   (ART.LOC_ID   =  'BXM' OR
    ART.LOC_ID   =  'GSV' OR
	ART.LOC_ID   =  'DSM' OR
    ART.LOC_ID   =  'BAU')
  AND
   ART.CUR_FLAG =  'y'
  AND
   ART.LEV_IND  <  250
  AND
   ART.PART_ID  NOT LIKE '%AE'
 ) SEL
ON
 (
  GTT.ARTCID = SEL.C_ID
 )
WHEN NOT MATCHED THEN
 INSERT
  (
     ARTCID
    ,PART_ID
    ,MCODE
    ,FREE_NAME
    ,LEV_IND
    ,UITVOERING
    ,SEL_FLAG
    ,ADTE
    ,LOC
    ,PLANT_ID
  )
 VALUES
  (
    SEL.C_ID
   ,SEL.PART_ID
   ,SEL.MCODE
   ,SEL.FREE_NAME
   ,SEL.LEV_IND
   ,SEL.UITVOERING
   ,1
   ,SEL.ADTE
   ,SEL.LOC_ID
   ,SEL.PLANT_ID
  )
;
COMMIT;

-- add machine commerical name to machine code to flagged items in global temporary table
UPDATE
 T_TI_DOC_REP GTT
SET
 MNAME_COM = 
  (
   SELECT
    MC.MNAME_COM
   FROM
    T_SFS_TSL_MC MC
   WHERE
    MC.MCODE = GTT.MCODE
  )
WHERE
 MCODE IS NOT NULL
AND
 SEL_FLAG = 1
;
COMMIT;

-- add related documents to flagged items in global temporary table
-- 1st type of related documents
UPDATE
 T_TI_DOC_REP GTT
SET
 DOC_LIST1 = 
  (
   SELECT
    LISTAGG(CASE WHEN DOC1.DOC_VERSION IS NULL THEN DOC1.DOCUMENT_ID ELSE DOC1.DOCUMENT_ID ||'_'||DOC1.DOC_VERSION END,' ') WITHIN GROUP (ORDER BY DOC1.DOCUMENT_ID)
   FROM
     T_TI_DOC_REP GTT1
    ,T_MASTER_DOC MD1
    ,T_DOC_DAT    DOC1
   WHERE
    GTT1.ARTCID       =  GTT.ARTCID
   AND
    GTT1.ARTCID       =  MD1.C_ID_1
   AND
    DOC1.C_ID         =  MD1.C_ID_2
   AND
    DOC1.DOC_TYPE     =  'PDF'
   AND
    DOC1.CAX_TYPE     =  'UM'
   AND
    DOC1.SHEET_NO     =  'ENG'
   AND
    DOC1.PMT_STBN_ENG != 'CONTROL PANEL'
   AND
    DOC1.CUR_FLAG     =  'y'
  )
WHERE
 SEL_FLAG = 1
;
COMMIT;

-- 2nd type of related documents
UPDATE
 T_TI_DOC_REP GTT
SET
 DOC_LIST2 = 
  (
   SELECT
    LISTAGG(CASE WHEN DOC1.DOC_VERSION IS NULL THEN DOC1.DOCUMENT_ID ELSE DOC1.DOCUMENT_ID ||'_'||DOC1.DOC_VERSION END,' ') WITHIN GROUP (ORDER BY DOC1.DOCUMENT_ID)
   FROM
     T_TI_DOC_REP GTT1
    ,T_MASTER_DOC MD1
    ,T_DOC_DAT    DOC1
   WHERE
    GTT1.ARTCID       =  GTT.ARTCID
   AND
    GTT1.ARTCID       =  MD1.C_ID_1
   AND
    DOC1.C_ID         =  MD1.C_ID_2
   AND
    DOC1.DOC_TYPE     =  'PDF'
   AND
    DOC1.CAX_TYPE     =  'UM'
   AND
    DOC1.SHEET_NO     =  'ENG'
   AND
    DOC1.PMT_STBN_ENG =  'CONTROL PANEL'
   AND
    DOC1.CUR_FLAG     =  'y'
  )
WHERE
 SEL_FLAG = 1
;
COMMIT;

-- 3rd type of related documents
UPDATE
 T_TI_DOC_REP GTT
SET
 DOC_LIST3 = 
  (
   SELECT
    LISTAGG(CASE WHEN DOC1.DOC_VERSION IS NULL THEN DOC1.DOCUMENT_ID ELSE DOC1.DOCUMENT_ID ||'_'||DOC1.DOC_VERSION END,' ') WITHIN GROUP (ORDER BY DOC1.DOCUMENT_ID)
   FROM
     T_TI_DOC_REP GTT1
    ,T_MASTER_DOC MD1
    ,T_DOC_DAT    DOC1
   WHERE
    GTT1.ARTCID       =  GTT.ARTCID
   AND
    GTT1.ARTCID       =  MD1.C_ID_1
   AND
    DOC1.C_ID         =  MD1.C_ID_2
   AND
    DOC1.DOC_TYPE     =  'PDF'
   AND
    DOC1.CAX_TYPE     =  'SUPPL'
   AND
    DOC1.SHEET_NO     =  'ENG'
   AND
    DOC1.CUR_FLAG     =  'y'
  )
WHERE
 SEL_FLAG = 1
;
COMMIT;

-- 4th type of related documents
UPDATE
 T_TI_DOC_REP GTT
SET
 DOC_LIST4 = 
  (
   SELECT
    LISTAGG(CASE WHEN DOC1.DOC_VERSION IS NULL THEN DOC1.DOCUMENT_ID ELSE DOC1.DOCUMENT_ID ||'_'||DOC1.DOC_VERSION END,' ') WITHIN GROUP (ORDER BY DOC1.DOCUMENT_ID)
   FROM
     T_TI_DOC_REP GTT1
    ,T_MASTER_DOC MD1
    ,T_DOC_DAT    DOC1
   WHERE
    GTT1.ARTCID       =  GTT.ARTCID
   AND
    GTT1.ARTCID       =  MD1.C_ID_1
   AND
    DOC1.C_ID         =  MD1.C_ID_2
   AND
    DOC1.DOC_TYPE     IN ('PDF','ACAD')
   AND
    DOC1.CAX_TYPE     IN ('TD','TEDA')
   AND
    DOC1.CUR_FLAG     =  'y'
  )
WHERE
 SEL_FLAG = 1
;
COMMIT;

--Insert the PCS_CODE in the main table
/*MERGE INTO T_TI_DOC_REP GTT
USING 
    (
  SELECT 
    ARTCID
    ,CLASS_CODE
  FROM 
    T_TI_REP_PCS
) GTPCS
ON (GTT.ARTCID = GTPCS.ARTCID)
WHEN MATCHED THEN
  UPDATE SET GTT.PCS_CODE = GTPCS.CLASS_CODE;
COMMIT;

UPDATE T_TI_DOC_REP GTT
SET PCS_CODE = (
  SELECT CLASS_CODE 
  FROM T_TI_REP_PCS 
  WHERE GTT.ARTCID = T_TI_REP_PCS.ARTCID
  AND ROWNUM = 1
);
UPDATE T_TI_DOC_REP GTT
SET PCS_CODE = '-' WHERE PCS_CODE IS NULL;
COMMIT;
*/

UPDATE T_TI_DOC_REP GTT
SET PCS_CODE = (
    SELECT LISTAGG(CLASS_CODE, ' ') WITHIN GROUP (ORDER BY CLASS_CODE) AS CLASS_CODES
    FROM T_TI_REP_PCS
    WHERE GTT.ARTCID = T_TI_REP_PCS.ARTCID
    )
WHERE EXISTS (
    SELECT 1
    FROM T_TI_REP_PCS
    WHERE GTT.ARTCID = T_TI_REP_PCS.ARTCID
    );
COMMIT;

UPDATE T_TI_DOC_REP GTT
SET PCS_CODE = '-' WHERE PCS_CODE IS NULL;
COMMIT;

-- create report of flagged entries in global temporary table 
-- header line
SELECT
 'Type|MC|Machine|Model|Modeltoevoeging|Gebr-aanw-|Besturingskast|Derden|ResTypedelen|Tech-dat-|Opmerking|Status|Hardloper|Locatie UM|Date|Location|Prod.-Line|PCS-Code'
FROM
 DUAL
;

-- data lines
SELECT
 PART_ID||'|'||
 MCODE||'|'||
 MNAME_COM||'|'||
 FREE_NAME||'||'||
 DOC_LIST1||'|'||
 DOC_LIST2||'|'||
 DOC_LIST3||'||'||
 DOC_LIST4||'||'||
 LEV_IND||'|||'||
 ADTE||'|'||
 LOC||'|'||
 PLANT_ID||'|'||
 PCS_CODE||'|'
FROM
 T_TI_DOC_REP
WHERE
 SEL_FLAG = 1
ORDER BY 
  PART_ID ASC
 ,MCODE ASC
;

-- empty and remove global temporary tables
TRUNCATE TABLE T_TI_DOC_REP;
DROP TABLE T_TI_DOC_REP;
TRUNCATE TABLE T_TI_REP_PCS;
DROP TABLE T_TI_REP_PCS;

SPOOL OFF;
EXIT
