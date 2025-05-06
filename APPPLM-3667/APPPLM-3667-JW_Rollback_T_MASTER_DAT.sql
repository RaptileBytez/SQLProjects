SELECT MAX(AGG_FLAG) FROM T_MASTER_DAT;
SELECT MAX(BOM_FLAG) FROM T_MASTER_DAT;

-- Create the new collumns in the table
ALTER TABLE
    T_MASTER_DAT
    ADD (
        AGG_FLAG_NEW NUMBER(4),
        BOM_FLAG_NEW NUMBER(4),
        AGG_FLAG_OLD NUMBER(6),
        BOM_FLAG_OLD NUMBER(6)
        );

-- Update the new collumns with the values from the old collumns
UPDATE
    T_MASTER_DAT
    SET
        AGG_FLAG_OLD = AGG_FLAG,
        BOM_FLAG_OLD = BOM_FLAG,
        AGG_FLAG_NEW = CASE WHEN AGG_FLAG <= 9999 THEN AGG_FLAG ELSE 9999 END,
        BOM_FLAG_NEW = CASE WHEN BOM_FLAG <= 9999 THEN BOM_FLAG ELSE 9999 END;

-- Check if all copies are correct
SELECT
    AGG_FLAG_NEW,
    BOM_FLAG_NEW
FROM
    T_MASTER_DAT
WHERE 
    AGG_FLAG_NEW > 9999 OR BOM_FLAG_NEW > 9999
    OR AGG_FLAG_NEW IS NULL OR BOM_FLAG_NEW IS NULL
    OR AGG_FLAG_OLD != AGG_FLAG OR BOM_FLAG_OLD != BOM_FLAG; -- Expected output: 0 rows

 -- Drop the original collumns
ALTER TABLE
    T_MASTER_DAT
    DROP COLUMN AGG_FLAG;
ALTER TABLE
    T_MASTER_DAT
    DROP COLUMN BOM_FLAG;

-- Rename the new collumns
ALTER TABLE
    T_MASTER_DAT
    RENAME COLUMN AGG_FLAG_NEW TO AGG_FLAG;
ALTER TABLE
    T_MASTER_DAT
    RENAME COLUMN BOM_FLAG_NEW TO BOM_FLAG;

-- Check Agile Repository fields
SELECT
    C_ID,
    C_TYPE, 
    C_NAME 
FROM T_FIELD 
WHERE 
    C_NAME = 'T_MASTER_DAT.AGG_FLAG' 
    OR C_NAME = 'T_MASTER_DAT.BOM_FLAG';

--Update Agile Repository fields
UPDATE T_FIELD
SET
    C_TYPE = 'I4'
 WHERE
    C_NAME = 'T_MASTER_DAT.AGG_FLAG'
    OR C_NAME = 'T_MASTER_DAT.BOM_FLAG';

-- Drop the old collumns
ALTER TABLE
    T_MASTER_DAT
    DROP COLUMN AGG_FLAG_OLD;
ALTER TABLE
    T_MASTER_DAT
    DROP COLUMN BOM_FLAG_OLD;

commit;