/**
Initial version of the script to mass update the PRIO field (AA_T_MASTER_DAT_ECL_APPPLM3083.PRIO).
Written by Jesco Wurm (ICP) on 19-03-2025
for APPPLM-3083 - As MAREL business we want to exclude some items on the Full item migration to DPH based on non-PLM only rules but based on item number
*/
SELECT COUNT (*) FROM T_MASTER_DAT WHERE MIGRATE = 'n';

SELECT * FROM T_MASTER_DAT WHERE MIGRATE = 'n' AND PART_ID NOT IN (SELECT PART_ID FROM AA_T_MASTER_DAT_ECL_APPPLM3083);

SELECT PART_ID, COUNT(*) FROM aa_t_master_dat_ecl_appplm3083
WHERE PRIO = 0
GROUP BY part_id
HAVING count(*) > 1;

SELECT DISTINCT PART_ID, LISTAGG(EXCL_ID, ',') WITHIN GROUP (ORDER BY EXCL_ID) AS EXCL_IDs
FROM aa_t_master_dat_ecl_appplm3083
WHERE PRIO = 0
GROUP BY PART_ID
HAVING COUNT(EXCL_ID) > 1;

SELECT * FROM aa_t_master_dat_ecl_appplm3083 WHERE EXCL_ID < 9;

-- set Prios to DUBLICATE PART_IDs to be ABLE TO SELECT the MAX PRO
UPDATE aa_t_master_dat_ecl_appplm3083
SET PRIO = 1
WHERE 
EXCL_ID = 2
OR EXCL_ID = 4
OR EXCL_ID = 6
OR EXCL_ID = 8
OR EXCL_ID = 420 
OR EXCL_ID = 643 
OR EXCL_ID = 701 
OR EXCL_ID = 991 
OR EXCL_ID = 1226 
OR EXCL_ID = 1273;
commit;

SELECT REASON 
    FROM T_MASTER_DAT parts,(
        SELECT PART_ID, REASON, ROW_NUMBER() OVER (PARTITION BY PART_ID ORDER BY PRIO DESC) rn
        FROM AA_T_MASTER_DAT_ECL_APPPLM3083
    ) exclude
    WHERE exclude.PART_ID = parts.PART_ID AND exclude.rn = 1;
