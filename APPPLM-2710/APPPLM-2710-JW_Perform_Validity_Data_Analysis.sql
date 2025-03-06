/*
Written by  :   Jesco Wurm - ICP Solution GmbH
Date        :   27-08-2024    
Function    :   Determination of invalid data (APPPLM-2710)
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

-- empty and remove possible existing global temporary tables
BEGIN
 EXECUTE IMMEDIATE 'TRUNCATE TABLE GTT_ELG_REP';
 EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN RAISE;
  END IF;
END;
/
BEGIN
 EXECUTE IMMEDIATE 'DROP TABLE GTT_ELG_REP';
 EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN RAISE;
  END IF;
END;
/
BEGIN
 EXECUTE IMMEDIATE 'TRUNCATE TABLE GTT_ELG_STR';
 EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN RAISE;
  END IF;
END;
/
BEGIN
 EXECUTE IMMEDIATE 'DROP TABLE GTT_ELG_STR';
 EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN RAISE;
  END IF;
END;
/
BEGIN
 EXECUTE IMMEDIATE 'TRUNCATE TABLE GTT_ELG_CHLD';
 EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN RAISE;
  END IF;
END;
/
BEGIN
 EXECUTE IMMEDIATE 'DROP TABLE GTT_ELG_CHLD';
 EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN RAISE;
  END IF;
END;
/
BEGIN
 EXECUTE IMMEDIATE 'TRUNCATE TABLE GTT_ELG_REPORT';
 EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN RAISE;
  END IF;
END;
/
BEGIN
 EXECUTE IMMEDIATE 'DROP TABLE GTT_ELG_REPORT';
 EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN RAISE;
  END IF;
END;
/
-- create new global temporary tables
CREATE GLOBAL TEMPORARY TABLE GTT_ELG_REP
(
    STR_CID Number(10),
    BLVL_CID Number(10),
    BLVL_PART_ID VARCHAR2(40 CHAR),
    BLVL_VERSION VARCHAR2(10 CHAR),
    BLVL_LEV_IND Number(10),
    BLVL_EDB_ID Number(10),
    BLVL_VAL_FROM DATE,
    BLVL_VAL_UNTIL DATE,
    BLVL_ART_TYP VARCHAR2 (2 CHAR),
    BLVL_SUBTYPE VARCHAR2 (5 CHAR),
    AMC DATE,
    AS_MAINT_SNO VARCHAR2(32 CHAR),
    ELG_CID Number(10),
    ELG_PART_ID VARCHAR2(40 CHAR),
    ELG_LEV_IND Number(10),
    ELG_VERSION VARCHAR2(10 CHAR),
    ELG_POS_NO Number(5),
    ELG_VAL_FROM DATE,
    ELG_VAL_UNTIL DATE,
    ELG_ART_TYP VARCHAR2 (2 CHAR),
    ELG_SUBTYPE VARCHAR2 (5 CHAR)
)
ON COMMIT PRESERVE ROWS;

CREATE GLOBAL TEMPORARY TABLE GTT_ELG_STR (
    STRUCTURE_DEPTH NUMBER,             -- Die Strukturtiefe (Level)
    INDENTED_C_ID VARCHAR2(4000 CHAR),       -- Der eingerückte Identifier des Kindes
    FULL_PATH VARCHAR2(4000 CHAR),           -- Der vollständige Pfad
    C_ID NUMBER(10),                    -- Die eindeutige Nummer (Identifier)
    C_ID_1 NUMBER(10),                  -- Der Identifier des Vaters
    C_ID_2 NUMBER(10),                  -- Der Identifier des Kindes
    POS_NO NUMBER(5)                    -- Die Positionsnummer
)
ON COMMIT PRESERVE ROWS;

CREATE GLOBAL TEMPORARY TABLE GTT_ELG_CHLD (
    CHLD_CID Number(10),
    CHLD_PART_ID VARCHAR2 (40 CHAR),
    CHLD_VERSION VARCHAR2(10 CHAR),
    CHLD_LEV_IND Number(10),
    CHLD_VAL_FROM DATE,
    CHLD_VAL_UNTIL DATE
)
ON COMMIT PRESERVE ROWS;

CREATE GLOBAL TEMPORARY TABLE GTT_ELG_REPORT(
    STRUCTURE_DEPTH Number(5),
    C_ID_1 Number(10),
    C_ID_2 Number(10),
    FULL_PATH VARCHAR2(4000 CHAR),
    POS_NO Number(5),
    ELG_C_ID Number(10),
    ELG_PART_ID VARCHAR2 (40 CHAR),
    ELG_VERSION VARCHAR2(10 CHAR),
    CHLD_PART_ID VARCHAR2 (40 CHAR),
    CHLD_VERSION VARCHAR2(10 CHAR),
    CHLD_LEV_IND Number(10),
    CHLD_VAL_FROM DATE,
    CHLD_VAL_UNTIL DATE,
    BLVL_PART_ID VARCHAR2 (40 CHAR),
    BLVL_VERSION VARCHAR2(10 CHAR),
    BLVL_VAL_FROM DATE,
    BLVL_VAL_UNTIL DATE,
    AMC DATE,
    AS_MAINT_SNO VARCHAR2(32 CHAR),
    ANALYSISRESULT VARCHAR2(50 CHAR)
)
ON COMMIT PRESERVE ROWS;

-- Get all B-Level Items which have an Electrical Legend within their Single Level BOM and their data from the relevant tables and store it in the GTT_ERP_REP table
MERGE INTO GTT_ELG_REP tgt
USING
(
    SELECT
        bom.C_ID AS STR_CID,
        bom.C_ID_1 AS BLVL_CID,
        md.PART_ID AS BLVL_PART_ID,
        md.PART_VERSION AS BLVL_VERSION,
        md.LEV_IND AS BLVL_LEV_IND,
        md.EDB_ID AS BLVL_EDB_ID,
        md.VAL_FROM AS BLVL_VAL_FROM,
        md.VAL_UNTIL AS BLVL_VAL_UNTIL,
        md.ART_TYP AS BLVL_ART_TYP,
        md.PART_SUBTYPE AS BLVL_SUBTYPE,
        bom.C_ID_2 AS ELG_CID,
        mco.C_CRE_DAT AS AMC,
        mco.SNO_MNT AS AS_MAINT_SNO,
        prt.PART_ID AS ELG_PART_ID,
        prt.PART_VERSION AS ELG_VERSION,
        bom.POS_NO AS ELG_POS_NO,
        prt.LEV_IND AS ELG_LEV_IND,
        prt.VAL_FROM AS ELG_VAL_FROM,
        prt.VAL_UNTIL AS ELG_VAL_UNTIL,
        prt.ART_TYP AS ELG_ART_TYP,
        prt.PART_SUBTYPE AS ELG_SUBTYPE
    FROM 
        T_MASTER_STR bom
    JOIN 
        T_MASTER_DAT md ON bom.C_ID_1 = md.C_ID
    JOIN
        T_CMG_MCO_DAT mco ON md.EDB_ID = mco.AS_MNT_REF
    JOIN
        T_MASTER_DAT prt ON bom.C_ID_2 = prt.C_ID
    WHERE 
        bom.C_ID_2 IN (SELECT C_ID FROM T_MASTER_DAT WHERE LEV_IND >= 230 AND LEV_IND <= 260 AND PART_SUBTYPE = 'ELG')
        AND md.ART_TYP = 'N'
) src
ON 
    (
    tgt.STR_CID = src.STR_CID
    )
WHEN NOT MATCHED THEN
 INSERT
  (
    tgt.STR_CID,
    tgt.BLVL_CID,
    tgt.BLVL_PART_ID,
    tgt.BLVL_VERSION,
    tgt.BLVL_LEV_IND,
    tgt.BLVL_EDB_ID,       
    tgt.BLVL_VAL_FROM,
    tgt.BLVL_VAL_UNTIL,
    tgt.BLVL_ART_TYP,
    tgt.BLVL_SUBTYPE,
    tgt.AMC,
    tgt.AS_MAINT_SNO,
    tgt.ELG_CID,
    tgt.ELG_PART_ID,
    tgt.ELG_VERSION,
    tgt.ELG_POS_NO,
    tgt.ELG_LEV_IND,
    tgt.ELG_VAL_FROM,
    tgt.ELG_VAL_UNTIL,
    tgt.ELG_ART_TYP,
    tgt.ELG_SUBTYPE
  )
 VALUES
  (
    src.STR_CID,
    src.BLVL_CID,
    src.BLVL_PART_ID,
    src.BLVL_VERSION,
    src.BLVL_LEV_IND,
    src.BLVL_EDB_ID,  
    src.BLVL_VAL_FROM,
    src.BLVL_VAL_UNTIL,
    src.BLVL_ART_TYP,
    src.BLVL_SUBTYPE,
    src.AMC,
    src.AS_MAINT_SNO,
    src.ELG_CID,
    src.ELG_PART_ID,
    src.ELG_VERSION,
    src.ELG_POS_NO,
    src.ELG_LEV_IND,
    src.ELG_VAL_FROM,
    src.ELG_VAL_UNTIL,
    src.ELG_ART_TYP,
    src.ELG_SUBTYPE
  );

COMMIT;

-- Create a structure explosion of all ELG items and store it in the table GTT_ELG_STR
INSERT INTO GTT_ELG_STR (STRUCTURE_DEPTH, INDENTED_C_ID, FULL_PATH, C_ID, C_ID_1, C_ID_2, POS_NO)
SELECT
    LEVEL AS STRUCTURE_DEPTH,
    LPAD(' ', (LEVEL - 1) * 2) || C_ID_2 AS INDENTED_C_ID,
    SYS_CONNECT_BY_PATH(C_ID_1, '/') || '/' || C_ID_2 AS FULL_PATH,
    T.C_ID,
    T.C_ID_1,
    T.C_ID_2,
    T.POS_NO
FROM
    T_MASTER_STR T
START WITH
    T.C_ID_1 IN (SELECT DISTINCT ELG_CID FROM GTT_ELG_REP)
CONNECT BY
    PRIOR T.C_ID_2 = T.C_ID_1
AND LEVEL <= 100
ORDER BY
    STRUCTURE_DEPTH, C_ID_1, POS_NO;

COMMIT;

-- Get the ELG-Child data and store it in GTT_ELG_CHLD
INSERT INTO GTT_ELG_CHLD (CHLD_CID, CHLD_PART_ID, CHLD_VERSION, CHLD_LEV_IND, CHLD_VAL_FROM, CHLD_VAL_UNTIL)
SELECT 
    C_ID,
    PART_ID,
    PART_VERSION,
    LEV_IND,
    VAL_FROM,
    VAL_UNTIL
FROM 
    T_MASTER_DAT chld
WHERE chld.C_ID IN (SELECT C_ID_2 FROM GTT_ELG_STR);

COMMIT;

INSERT INTO GTT_ELG_REPORT (
    STRUCTURE_DEPTH,
    C_ID_1,
    C_ID_2,
    FULL_PATH,
    POS_NO,
    ELG_C_ID,
    ELG_PART_ID,
    ELG_VERSION,
    CHLD_PART_ID,
    CHLD_VERSION,
    CHLD_LEV_IND,
    CHLD_VAL_FROM,
    CHLD_VAL_UNTIL,
    BLVL_PART_ID,
    BLVL_VERSION,
    BLVL_VAL_FROM,
    BLVL_VAL_UNTIL,
    AMC,
    AS_MAINT_SNO,
    ANALYSISRESULT
)
WITH elg_str_cte AS (
    SELECT 
        x.STRUCTURE_DEPTH,
        x.FULL_PATH,
        x.C_ID_1,
        x.C_ID_2,
        x.POS_NO,
        TO_NUMBER(SUBSTR(FULL_PATH, 2, INSTR(FULL_PATH, '/', 2) - 2)) AS ELG_C_ID
    FROM 
        GTT_ELG_STR x
)
SELECT 
    x.STRUCTURE_DEPTH,
    x.C_ID_1,
    x.C_ID_2,
    x.FULL_PATH,
    x.POS_NO,
    x.ELG_C_ID,
    z.ELG_PART_ID,
    z.ELG_VERSION,
    y.chld_part_id,
    y.chld_version,
    y.chld_lev_ind,
    y.chld_val_from,
    y.chld_val_until,
    z.blvl_part_id,
    z.blvl_version,
    z.blvl_val_from,
    z.blvl_val_until,
    z.amc,
    z.as_maint_sno,
    CASE
        WHEN (y.chld_val_from <= z.blvl_val_from) AND (y.chld_val_until >= z.amc OR y.chld_val_until IS NULL) THEN 'OK'
        WHEN (y.chld_val_from > z.blvl_val_from) AND (y.chld_val_until < z.amc) THEN TO_CHAR(x.STRUCTURE_DEPTH)
        WHEN (y.chld_val_from <= z.blvl_val_from) AND (y.chld_val_until > z.blvl_val_from) AND (y.chld_val_until < z.amc) THEN TO_CHAR(x.STRUCTURE_DEPTH)
        WHEN (y.chld_val_from > z.blvl_val_from) AND (y.chld_val_from < z.amc) AND (y.chld_val_until >= z.amc OR y.chld_val_until IS NULL) THEN TO_CHAR(x.STRUCTURE_DEPTH)
        -- Zusätzliche Fälle:
        WHEN y.chld_val_from > z.amc AND (y.chld_val_until >= z.amc OR y.chld_val_until IS NULL) THEN 'After AMC'
        WHEN y.chld_val_from < z.amc AND y.chld_val_until > z.amc THEN 'Partially After AMC'
        WHEN y.chld_val_from <= z.blvl_val_from AND y.chld_val_until < z.amc THEN 'Before BF'
        WHEN y.chld_val_from < z.blvl_val_from AND y.chld_val_until <= z.blvl_val_from THEN 'Partially Before BF'
        ELSE 'N/A'
    END AS ANALYSISRESULT
FROM 
    elg_str_cte x
JOIN GTT_ELG_CHLD y ON x.C_ID_2 = y.chld_cid
JOIN GTT_ELG_REP z ON x.ELG_C_ID = z.ELG_CID;


-- create  complete report
SPOOL C:\Temp\ELG_ANALYSIS_COMPLETE-&DATEVAR..csv;
-- header line
SELECT
 'STRUCTURE_DEPTH|FULL_PATH|POS_NO|ELG_PART_ID|ELG_VERSION|CHLD_PART_ID|CHLD_VERSION|CHLD_LEV_IND|CHLD_VAL_FROM|CHLD_VAL_UNTIL|BLVL_PART_ID|BLVL_VERSION|BLVL_VAL_FROM|BLVL_VAL_UNTIL|AMC|AS_MAINT_SNO|ANALYSISRESULT'
FROM
 DUAL
;

-- data lines
SELECT
    STRUCTURE_DEPTH||'|'||
    FULL_PATH||'|'||
    POS_NO||'|'||
    ELG_PART_ID||'|'||
    ELG_VERSION||'|'||
    CHLD_PART_ID||'|'||
    CHLD_VERSION||'|'||
    CHLD_LEV_IND||'|'||
    CHLD_VAL_FROM||'|'||
    CHLD_VAL_UNTIL||'|'||
    BLVL_PART_ID||'|'||
    BLVL_VERSION||'|'||
    BLVL_VAL_FROM||'|'||
    BLVL_VAL_UNTIL||'|'||
    AMC||'|'||
    AS_MAINT_SNO||'|'||
    ANALYSISRESULT
FROM
    GTT_ELG_REPORT;
    
SPOOL OFF;

-- create  complete report
SPOOL C:\Temp\ELG_ANALYSIS_NOTOK-&DATEVAR..csv;
-- header line
SELECT
 'STRUCTURE_DEPTH|FULL_PATH|POS_NO|ELG_PART_ID|ELG_VERSION|CHLD_PART_ID|CHLD_VERSION|CHLD_LEV_IND|CHLD_VAL_FROM|CHLD_VAL_UNTIL|BLVL_PART_ID|BLVL_VERSION|BLVL_VAL_FROM|BLVL_VAL_UNTIL|AMC|AS_MAINT_SNO|ANALYSISRESULT'
FROM
 DUAL
;

-- data lines
SELECT
    STRUCTURE_DEPTH||'|'||
    FULL_PATH||'|'||
    POS_NO||'|'||
    ELG_PART_ID||'|'||
    ELG_VERSION||'|'||
    CHLD_PART_ID||'|'||
    CHLD_VERSION||'|'||
    CHLD_LEV_IND||'|'||
    CHLD_VAL_FROM||'|'||
    CHLD_VAL_UNTIL||'|'||
    BLVL_PART_ID||'|'||
    BLVL_VERSION||'|'||
    BLVL_VAL_FROM||'|'||
    BLVL_VAL_UNTIL||'|'||
    AMC||'|'||
    AS_MAINT_SNO||'|'||
    ANALYSISRESULT
FROM
    GTT_ELG_REPORT
WHERE ANALYSISRESULT != 'OK';  
SPOOL OFF;

--Statistics:
SPOOL C:\Temp\ELG_ANALYSIS_STATS-&DATEVAR..csv;
-- Header Line
SELECT
 'TOTAL_COUNT|OK_COUNT|OK_PERCENTAGE|NOT_APPLICABLE_COUNT|NOT_APPLICABLE_PERCENTAGE|AFTER_AMC_COUNT|AFTER_AMC_PERCENTAGE|BEFORE_BF_COUNT|BEFORE_BF_PERCENTAGE|ERROR_IN_DEPTH_1_COUNT|ERROR_IN_DEPTH_1_PERCENTAGE|ERROR_IN_DEPTH_2_COUNT|ERROR_IN_DEPTH_2_PERCENTAGE|ERROR_IN_DEPTH_3_COUNT|ERROR_IN_DEPTH_3_PERCENTAGE|ERROR_IN_DEPTH_4_COUNT|ERROR_IN_DEPTH_4_PERCENTAGE|ERROR_IN_DEPTH_5_COUNT|ERROR_IN_DEPTH_5_PERCENTAGE|ERROR_IN_DEPTH_6_COUNT|ERROR_IN_DEPTH_6_PERCENTAGE|ERROR_IN_DEPTH_7_COUNT|ERROR_IN_DEPTH_7_PERCENTAGE'
FROM DUAL;

-- Data Line
SELECT 
    COUNT(*)||'|'||
    
    SUM(CASE WHEN ANALYSISRESULT = 'OK' THEN 1 ELSE 0 END)||'|'||
    TO_CHAR(ROUND(SUM(CASE WHEN ANALYSISRESULT = 'OK' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2), 'FM9990.00')||'|'||
    
    SUM(CASE WHEN ANALYSISRESULT = 'N/A' THEN 1 ELSE 0 END)||'|'||
    TO_CHAR(ROUND(SUM(CASE WHEN ANALYSISRESULT = 'N/A' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2), 'FM9990.00')||'|'||
    
    SUM(CASE WHEN ANALYSISRESULT = 'After AMC' THEN 1 ELSE 0 END)||'|'||
    TO_CHAR(ROUND(SUM(CASE WHEN ANALYSISRESULT = 'After AMC' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2), 'FM9990.00')||'|'||
    
    SUM(CASE WHEN ANALYSISRESULT = 'Before BF' THEN 1 ELSE 0 END)||'|'||
    TO_CHAR(ROUND(SUM(CASE WHEN ANALYSISRESULT = 'Before BF' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2), 'FM9990.00')||'|'||
    
    SUM(CASE WHEN ANALYSISRESULT = '1' THEN 1 ELSE 0 END)||'|'||
    TO_CHAR(ROUND(SUM(CASE WHEN ANALYSISRESULT = '1' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2), 'FM9990.00')||'|'||
    
    SUM(CASE WHEN ANALYSISRESULT = '2' THEN 1 ELSE 0 END)||'|'||
    TO_CHAR(ROUND(SUM(CASE WHEN ANALYSISRESULT = '2' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2), 'FM9990.00')||'|'||
    
    SUM(CASE WHEN ANALYSISRESULT = '3' THEN 1 ELSE 0 END)||'|'||
    TO_CHAR(ROUND(SUM(CASE WHEN ANALYSISRESULT = '3' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2), 'FM9990.00')||'|'||
    
    SUM(CASE WHEN ANALYSISRESULT = '4' THEN 1 ELSE 0 END)||'|'||
    TO_CHAR(ROUND(SUM(CASE WHEN ANALYSISRESULT = '4' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2), 'FM9990.00')||'|'||
    
    SUM(CASE WHEN ANALYSISRESULT = '5' THEN 1 ELSE 0 END)||'|'||
    TO_CHAR(ROUND(SUM(CASE WHEN ANALYSISRESULT = '5' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2), 'FM9990.00')||'|'||
    
    SUM(CASE WHEN ANALYSISRESULT = '6' THEN 1 ELSE 0 END)||'|'||
    TO_CHAR(ROUND(SUM(CASE WHEN ANALYSISRESULT = '6' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2), 'FM9990.00')||'|'||
    
    SUM(CASE WHEN ANALYSISRESULT = '7' THEN 1 ELSE 0 END)||'|'||
    TO_CHAR(ROUND(SUM(CASE WHEN ANALYSISRESULT = '7' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2), 'FM9990.00')

FROM 
    GTT_ELG_REPORT;

SPOOL OFF;

-- empty and remove global temporary tables
TRUNCATE TABLE GTT_ELG_REP;
DROP TABLE GTT_ELG_REP;
TRUNCATE TABLE GTT_ELG_STR;
DROP TABLE GTT_ELG_STR;
TRUNCATE TABLE GTT_ELG_CHLD;
DROP TABLE GTT_ELG_CHLD;
TRUNCATE TABLE GTT_ELG_REPORT;
DROP TABLE GTT_ELG_REPORT;

EXIT