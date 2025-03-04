/**
Initial version of the view V_PLM_DPH_DOC.
Written by Jesco Wurm (ICP) on 04-03-2025
for APPPLM-3589 - As a PLM Administrator, I want to adapt the ECO Documents queue to show proper OriginalFileName for interfacing with DPH.
*/
CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_PLM_DPH_DOC"
("ECO_NUMBER", "ECO_DOC_INTGR_JOB_STATUS", "ECO_DOC_INTGR_JOB_ERR_MESS", 
   "DOC_CID", "DOCUMENT_ID", "DOC_VERSION", "PMT_STBN_ENG", "FREE_NAME", "DOC_TYPE", "DOC_SUBTYPE", 
   "CAX_TYPE", "FILE_FORMAT", "FILE_CID", "EDB_ID", "ORG_FILE_NAME")
DEFAULT COLLATION "USING_NLS_COMP" 
AS
WITH ORG_FILE_NAME AS (
    SELECT d.c_id AS doc_cid,
           f.c_id AS file_cid,
           CASE 
               WHEN d.doc_type = 'EPLANP' THEN
                   (SELECT f1.org_name
                    FROM t_file_dat f1
                    JOIN t_doc_fil df1 ON df1.c_id_2 = f1.c_id AND df1.c_id_1 = d.c_id AND df1.c_id > 0
                    JOIN t_fil_store fs1 ON fs1.c_id_1 = f1.c_id AND fs1.c_id > 0
                    JOIN t_store_area sa1 ON sa1.c_id = fs1.c_id_2 AND sa1.site = 'dc1' AND sa1.c_id > 0
                    WHERE f1.file_format = 'ZIP' AND f1.file_type != 'doc' FETCH FIRST 1 ROW ONLY)
               WHEN d.doc_type = 'SOF' AND d.cax_type = 'SRC' THEN
                   (SELECT f2.org_name
                    FROM t_file_dat f2
                    JOIN t_doc_fil df2 ON df2.c_id_2 = f2.c_id AND df2.c_id_1 = d.c_id AND df2.c_id > 0
                    JOIN t_fil_store fs2 ON fs2.c_id_1 = f2.c_id AND fs2.c_id > 0
                    JOIN t_store_area sa2 ON sa2.c_id = fs2.c_id_2 AND sa2.site = 'dc1' AND sa2.c_id > 0
                    WHERE f2.file_format = 'ZIP' FETCH FIRST 1 ROW ONLY)
               WHEN d.doc_type = 'SOF' AND d.cax_type IN ('DEFCFG', 'CUSCFG') THEN
                   (SELECT org_name FROM (
                        SELECT f3.org_name,
                               ROW_NUMBER() OVER (ORDER BY 
                                   CASE 
                                       WHEN f3.org_name LIKE '%.zip' THEN 1
                                       WHEN f3.org_name LIKE '%.7z' THEN 2
                                       WHEN f3.org_name LIKE '%.pdf' THEN 3
                                       ELSE 4
                                   END) AS rn
                        FROM t_file_dat f3
                        JOIN t_doc_fil df3 ON df3.c_id_2 = f3.c_id AND df3.c_id_1 = d.c_id AND df3.c_id > 0
                        JOIN t_fil_store fs3 ON fs3.c_id_1 = f3.c_id AND fs3.c_id > 0
                        JOIN t_store_area sa3 ON sa3.c_id = fs3.c_id_2 AND sa3.site = 'dc1' AND sa3.c_id > 0
                        WHERE f3.file_format IN ('ZIP', 'PDF', '7Z')
                    ) WHERE rn = 1 FETCH FIRST 1 ROW ONLY)
               WHEN d.doc_type = 'SCAN' THEN
                   (SELECT org_name FROM (
                        SELECT f4.org_name,
                               ROW_NUMBER() OVER (ORDER BY 
                                   CASE 
                                       WHEN REGEXP_LIKE(REGEXP_SUBSTR(f4.org_name, '^[^._]+'), '^[0-9]+$')
                                       THEN TO_NUMBER(REGEXP_SUBSTR(f4.org_name, '^[^._]+'))
                                       ELSE NULL
                                   END) AS rn
                        FROM t_file_dat f4
                        JOIN t_doc_fil df4 ON df4.c_id_2 = f4.c_id AND df4.c_id_1 = d.c_id AND df4.c_id > 0
                        JOIN t_fil_store fs4 ON fs4.c_id_1 = f4.c_id AND fs4.c_id > 0
                        JOIN t_store_area sa4 ON sa4.c_id = fs4.c_id_2 AND sa4.site = 'dc1' AND sa4.c_id > 0
                        WHERE f4.file_format = 'PDF'
                    ) WHERE rn = 1 FETCH FIRST 1 ROW ONLY)
               ELSE
                   (SELECT f5.org_name
                    FROM t_file_dat f5
                    JOIN t_doc_fil df5 ON df5.c_id_2 = f5.c_id AND df5.c_id_1 = d.c_id AND df5.c_id > 0
                    JOIN t_fil_store fs5 ON fs5.c_id_1 = f5.c_id AND fs5.c_id > 0
                    JOIN t_store_area sa5 ON sa5.c_id = fs5.c_id_2 AND sa5.site = 'dc1' AND sa5.c_id > 0
                    WHERE f5.file_format = 'NATIVE' FETCH FIRST 1 ROW ONLY)
           END AS org_file_name
    FROM t_doc_dat d
    LEFT JOIN t_doc_fil df ON df.c_id_1 = d.c_id
    LEFT JOIN t_file_dat f ON df.c_id_2 = f.c_id
)
SELECT e.eco_number,
       e.eco_doc_intgr_job_status,
       e.eco_doc_intgr_job_err_mess,
       d.c_id AS doc_cid,
       d.document_id,
       d.doc_version,
       d.pmt_stbn_eng,
       d.free_name,
       d.doc_type,
       d.doc_subtype,
       d.cax_type,
       f.file_format,
       f.c_id AS file_cid,
       d.edb_id,
       ofn.org_file_name       
FROM t_doc_dat d
LEFT JOIN t_erp_eco_doc e ON d.c_id = e.doc_cid
LEFT JOIN ORG_FILE_NAME ofn ON d.c_id = ofn.doc_cid
LEFT JOIN t_doc_fil df ON d.c_id = df.c_id_1
LEFT JOIN t_file_dat f ON df.c_id_2 = f.c_id;
