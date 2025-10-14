prompt Learningguide link 
select EDB_VALUE from t_cfg_dat where EDB_ID  = 'EDB-HLP-LINK-SFS-LG';
prompt stamp process state
select edb_id, edb_value from T_CFG_DAT where EDB_ID like 'SFS-STAMP-BATCH%';
prompt Delete Login history 
select count(*) from T_SFS_FS_LOG;
select count(*) from T_LOGIN_HIS;

prompt Set IP-addresses of storage-nodes site-specific
select SITE, STORE_NODE, count(*) from T_STORE_AREA group by SITE, STORE_NODE;

prompt Execute the procedure delSiteFromEnvironment for each affected site: T_DFM_TAR_ARE
select SITE, count(*) from T_DFM_TAR_ARE group by SITE;

prompt Vault actions for shared fileservers
select substr(STORAGE_AREA, 1, 3), substr(STORE_DISCPATH, 1, 3), SITE, count(*) from T_STORE_AREA group by substr(STORAGE_AREA, 1, 3), substr(STORE_DISCPATH, 1, 3), SITE;
select substr(STORAGE_AREA, 1, 3), count(*) from T_STORE_AREA group by substr(STORAGE_AREA, 1, 3);
select substr(STORAGE_AREA, 1, 3), SITE, count(*) from T_DFM_TAR_ARE group by substr(STORAGE_AREA, 1, 3), SITE;

prompt AutoVue: Deleting PLM-configuration parameters %PVM% not belonging to these sites
select EDB_ID2, count(*) from T_CFG_DAT where T_CFG_DAT.EDB_ID like '%PVM%' group by EDB_ID2;

prompt AutoVue: Updating PLM-configuration parameters by replacing values
select edb_id, edb_id2, edb_value from T_CFG_DAT where T_CFG_DAT.EDB_ID like '%PVM-AV%' order by 1, 2;

prompt Allowed FMS Paths
select EDB_ID, EDB_VALUE from T_CFG_DAT where edb_id IN ('SFS-ERP-PRC','SFS-ERP-NRA','SFS-ERP-DAX');

prompt Disabling site-replication for all sites
select SITE, SFS_RPL_JOB_MAX, SFS_MAIL_STATE from T_DDM_SIT;

prompt Update PPO configuration
select SYSPAR_VALUE from T_PPO_ASV_SPA where T_PPO_ASV_SPA.C_ID_1 in ( select C_ID
                                    from  T_PPO_ASV
                                    where T_PPO_ASV.DEF_ID = 'SFS-central'
                                  )
      and T_PPO_ASV_SPA.C_ID_2 in ( select C_ID 
                                    from T_PPO_SPA 
                                    where T_PPO_SPA.PAR_NAME = 'PPO_JOB_DIR'
                                   );
select EDB_VALUE from T_CFG_DAT 
    where EDB_ID = 'PPO_JOB_DIR'
      and C_ID = ( select a3.C_ID 
                   from T_CFG_DAT a3    
                   inner join T_CFG_STR a2 on a3.C_ID = a2.c_id_2   
                   inner join T_CFG_DAT a1 on a1.C_ID = a2.C_ID_1   
                   where a1.EDB_ID = 'EDB-FMS-ALLOWED-PATHS'
                     and a3.EDB_ID = 'PPO_JOB_DIR'
              );
              
prompt Update export-processes
select OUTPUT_DIR, count(*) from SFS_PRC_CITY group by OUTPUT_DIR order by 1;
select ex.PRC_ID_PLM, cit.LOC_ID, pc.DSF_SERVER_REMOTE from SFS_PRC_CITY pc, T_CITY_DAT cit, T_EXP_PRC ex where pc.C_ID_2 = cit.C_ID and pc.C_ID_1 = ex.c_id
 and PRC_ID_PLM = 'PDFPRINT';
select ex.PRC_ID_PLM, cit.LOC_ID, pc.DSF_SERVER_REMOTE from SFS_PRC_CITY pc, T_CITY_DAT cit, T_EXP_PRC ex where pc.C_ID_2 = cit.C_ID and pc.C_ID_1 = ex.c_id
 and PRC_ID_PLM = 'PDFPRINTPICKUP';
select ex.PRC_ID_PLM, cit.LOC_ID, pc.DSF_SERVER_REMOTE, pc.PLOT_SITE, count(*) from SFS_PRC_CITY pc, T_CITY_DAT cit, T_EXP_PRC ex where pc.C_ID_2 = cit.C_ID and pc.C_ID_1 = ex.c_id
 and PRC_ID_PLM like 'CONVERT%' or PRC_ID_PLM like 'IGES%' or ( PRC_ID_PLM = 'EXPORT_NATIVE' and TOOL = 'ACAD') 
 group by ex.PRC_ID_PLM, cit.LOC_ID, pc.DSF_SERVER_REMOTE, pc.PLOT_SITE order by 1, 2, 3, 4;
select ex.PRC_ID_PLM, cit.LOC_ID, pc.PLOT_SITE, count(*) from SFS_PRC_CITY pc, T_CITY_DAT cit, T_EXP_PRC ex where pc.C_ID_2 = cit.C_ID and pc.C_ID_1 = ex.c_id
 and (( PRC_ID_PLM like 'CONVERT%' or PRC_ID_PLM like 'IGES%') and TOOL not in ('INVMOD', 'INVDRW', 'PROEM', 'PROED')) 
 group by ex.PRC_ID_PLM, cit.LOC_ID, pc.PLOT_SITE order by 1, 2, 3;
select ex.PRC_ID_PLM, cit.LOC_ID, pc.DSF_SERVER_REMOTE, count(*) from SFS_PRC_CITY pc, T_CITY_DAT cit, T_EXP_PRC ex where pc.C_ID_2 = cit.C_ID and pc.C_ID_1 = ex.c_id
 and (PRC_ID_PLM = 'ABC_EXPORT' or PRC_ID_PLM = 'MWO-EXPORT')
 group by ex.PRC_ID_PLM, cit.LOC_ID, pc.DSF_SERVER_REMOTE order by 1, 2, 3;
select ex.PRC_ID_PLM, cit.LOC_ID, pc.PLOT_SITE, count(*) from SFS_PRC_CITY pc, T_CITY_DAT cit, T_EXP_PRC ex where pc.C_ID_2 = cit.C_ID and pc.C_ID_1 = ex.c_id
 and PRC_ID_PLM in  ( 'CREATE-DXF', 'CREATE-PDF', 'CREATE-THUMBNAIL', 'REFILE', 'SAVE', 'CREATE-DXF-WHOLE' ) 
 group by ex.PRC_ID_PLM, cit.LOC_ID, pc.PLOT_SITE order by 1, 2, 3;

prompt Update Creo norm models' location
select CAX_FIL_PATH, count(*) from T_DOC_DAT where DOC_TYPE = 'PROEM' 
       and CAX_FIL_DISC = 'P:' 
       and substr(lower(CAX_FIL_PATH), 1, 8) = '\library'
       group by CAX_FIL_PATH order by 1;
select CAX_FIL_OLD_PATH, count(*) from T_DOC_DAT where DOC_TYPE = 'PROEM' 
       and CAX_FIL_OLD_PATH like 'P:\Library%'
       group by CAX_FIL_OLD_PATH order by 1;
select c_value from T_DEFAULT where C_NAME = 'SFS-CREO-LOC-LOC';

prompt Changes of e-mail-sender information
select S_EMAIL, count(*) from T_PRS_DAT group by S_EMAIL;
select edb_ID, EDB_VALUE from T_CFG_DAT 
    where C_ID in ( select c2.C_ID 
                    from T_CFG_DAT c1, 
                         T_CFG_STR cs, 
                         T_CFG_DAT c2 
                    where c1.C_ID = cs.C_ID_1 
                      and cs.C_ID_2 = c2.c_id 
                      and c1.EDB_ID = 'SFS-MAIL-ADDRESS' 
                  );

prompt Changes of user accounts
select c_name, c_pwd_nam, c_mng_flg from T_USER where c_disabled = 'n' order by 3, 1;
select SFS_INACT_DESCR, C_DISABLED, count(*) from T_USER group by SFS_INACT_DESCR, C_DISABLED;
