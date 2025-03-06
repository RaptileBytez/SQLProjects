SELECT master.c_ID, master.part_id, master.migrate, master.migrate_rule
FROM
    T_MASTER_DAT master
WHERE
    MIGRATE = 'n';
    
-- Query the items that should not be updated
SELECT master.c_ID, master.part_id, master.migrate, master.migrate_rule, exclude.reason, exclude.prio
FROM
    T_MASTER_DAT master,
    AA_T_MASTER_DAT_ECL_APPPLM3083 exclude

where master.part_id = exclude.part_id;

-- Find out if there is any any example in the system:
SELECT COUNT(*) FROM T_MASTER_DAT WHERE MIGRATE = 'n' AND PART_ID IN (SELECT PART_ID FROM AA_T_MASTER_DAT_ECL_APPPLM3083);

--create example data
UPDATE T_MASTER_DAT
SET migrate = 'n' WHERE C_ID = 1748938253;
commit;

-- Check what rows the current statement would update
SELECT C_ID, PART_ID, MIGRATE, MIGRATE_RULE
FROM T_MASTER_DAT WHERE MIGRATE = 'n' AND PART_ID IN (SELECT PART_ID FROM AA_T_MASTER_DAT_ECL_APPPLM3083);

-- Try the new Update Satement. it should update the row count from above in this case 13
UPDATE T_MASTER_DAT 
SET MIGRATE = null, MIGRATE_RULE = null 
WHERE MIGRATE = 'n' AND PART_ID NOT IN (SELECT PART_ID FROM AA_T_MASTER_DAT_ECL_APPPLM3083);

--
SELECT PART_ID, REASON, COUNT(*)
FROM AA_T_MASTER_DAT_ECL_APPPLM3083
GROUP BY PART_ID, REASON
HAVING COUNT(*) > 1;


-- The update the Parts with the Reason
UPDATE T_MASTER_DAT parts
SET parts.MIGRATE = 'n', parts.MIGRATE_RULE = (SELECT REASON FROM AA_T_MASTER_DAT_ECL_APPPLM3083 exclude WHERE exclude.PART_ID = parts.PART_ID AND PRIORITY = MAX(PRIORITY))
WHERE parts.PART_ID IN (SELECT PART_ID FROM AA_T_MASTER_DAT_ECL_APPPLM3083);

UPDATE T_MASTER_DAT parts
SET parts.MIGRATE = 'n', parts.MIGRATE_RULE = (
    SELECT REASON 
    FROM (
        SELECT PART_ID, REASON, ROW_NUMBER() OVER (PARTITION BY PART_ID ORDER BY PRIO DESC) rn
        FROM AA_T_MASTER_DAT_ECL_APPPLM3083
    ) exclude
    WHERE exclude.PART_ID = parts.PART_ID AND exclude.rn = 1
)
WHERE parts.PART_ID IN (SELECT PART_ID FROM AA_T_MASTER_DAT_ECL_APPPLM3083);


--rollback the update
Rollback;

-- roll back the example data
UPDATE T_MASTER_DAT
SET migrate = null WHERE C_ID = 1748938253;
commit;