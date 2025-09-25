SELECT DISTINCT 
    parent.C_ID,
    parent.PART_ID,
    parent.PART_VERSION,
    parent.LEV_IND AS PARENT_LEVEL,
    parent.PART_SUBTYPE,
    str.C_ID AS BOM_CID,
    str.POS_NO,
    child.C_ID AS CHILD_CID,
    child.PART_ID AS CHILD_ID,
    child.PART_VERSION AS CHILD_VERSION,
    child.LEV_IND AS CHILD_LEVEL,
    child.PART_SUBTYPE AS CHILD_TYPE
FROM T_MASTER_STR str
INNER JOIN T_MASTER_DAT child
    ON child.C_ID = str.C_ID_2
INNER JOIN T_MASTER_DAT parent
    ON parent.C_ID = str.C_ID_1
WHERE child.C_ID = 1110683590
    -- child.PART_ID = '000257014'
  AND str.SPARE = 'S';

SELECT 
    str.C_ID, 
    str.C_ID_1, 
    fat.PART_ID AS FAT_ID, 
    fat.PART_VERSION AS FAT_VERSION, 
    fat.LEV_IND AS FAT_LEVEL, str.C_ID_2, 
    child.PART_ID AS CHILD_ID, 
    child.PART_VERSION AS CHILD_VERSION, 
    child.LEV_IND AS CHILD_LEVEL, 
    str.POS_NO,
    str.SPARE
FROM 
    T_MASTER_STR str
LEFT JOIN 
    T_MASTER_DAT fat
ON 
    str.C_ID_1 = fat.C_ID
LEFT JOIN 
    T_MASTER_DAT child
ON 
    str.C_ID_2 = child.C_ID
WHERE 
-- str.SPARE = 'S' AND
str.C_ID_1 = 
;

SELECT COUNT(str.C_ID_1)
FROM T_MASTER_STR str
INNER JOIN T_MASTER_DAT child
ON child.C_ID = str.C_ID_2
WHERE child.PART_ID = '000257014'
AND str.SPARE = 'S';