set serveroutput on size 200000
set verify off
set heading off
set feedback off
ACCEPT DbEnv PROMPT 'DB-environment to execute PostRefresh-actions (BLD,PQE,QS,CptOne) : '

--set execution-controls. Can be overwritten by the following setup-configuration to disable/enable certain change-logic
define runAllEnvironmentGenericChange = FALSE
define runStorageNodeChange = FALSE
define runDelSite = FALSE
define runVaultAct = FALSE
define runDelPVMCfg = FALSE
define runReplCfgVal = FALSE
define runAllowedPath = FALSE
define runDisableSiteRepl = FALSE
define runPpoCfg = FALSE
define runExpProc = FALSE
define runCreoNrmModLoc = FALSE
define runEMailAddress = FALSE
define runUsers = FALSE
define runEnableUserGroups = FALSE
define runEnableTST_Users = FALSE
define runTrackUrl = FALSE
define runVaultUrl = FALSE
--added for APPPLM-3792
define runMpsTasksUpd = FALSE

--location of the post-action-scripts
define SCRIPT_PATH = C:\LocalData\SourceTree\deployment\RefreshDB
spool "&SCRIPT_PATH\RefreshDB_PostAction.log"
--execute the environment-specific setting: 
prompt read environment-specific values from RefreshDB_PostAction_setup.&DbEnv
@"&SCRIPT_PATH\RefreshDB_PostAction_setup.&DbEnv"


--Statements with fixed values for all environments
prompt .
prompt Running generic changes for all environments
declare
    sSQL varchar2(2000);
Begin
  if '&runAllEnvironmentGenericChange' = 'TRUE'  then
	update T_CFG_DAT 
	set EDB_VALUE = 'STOPPED' 
	where EDB_ID like 'SFS-STAMP-BATCH%' 
	and EDB_ID != 'SFS-STAMP-BATCH-DC1';
    DBMS_OUTPUT.put_line ( 'T_CFG_DAT: '||SQL%rowcount||' records updated.' );
	DBMS_OUTPUT.put_line ('Delete Login history by truncating T_SFS_FS_LOG and T_LOGIN_HIS');
	sSQL := 'truncate table "T_SFS_FS_LOG" drop storage';
    Execute immediate sSQL;
	sSQL := 'truncate table "T_LOGIN_HIS" drop storage';
    Execute immediate sSQL;
  else
    DBMS_OUTPUT.put_line ('Skipped for environment "'||'&DbEnv'||'".' );
  end if;
End;
/

prompt .
prompt Set IP-addresses of storage-nodes site-specific
declare
 siteList varchar2(2000);
 StoreNodeList varchar2(2000);
 siteVal varchar2(10);
 StoreNodeVal varchar2(255);
Begin
  if '&runStorageNodeChange' = 'TRUE'  then
    -- Initialize all Storage-areas with a not existing node-IP-address ("1"):
    update t_store_area set store_node = '1'; 
    siteList := '&siteList01';
    StoreNodeList  := '&StoreNodeList';
    while length( siteList ) > 0 Loop
      if  instr ( siteList , ',' ) > 0 then
        siteVal :=  substr ( siteList , 1 , instr ( siteList , ',' ) - 1 );
        siteList := substr ( siteList , instr ( siteList , ',' ) + 1  , length( siteList ) );
        StoreNodeVal := substr ( StoreNodeList , 1 , instr ( StoreNodeList , ',' ) - 1 );
        StoreNodeList := substr ( StoreNodeList , instr ( StoreNodeList , ',' ) + 1  , length( StoreNodeList ) );
      else
        siteVal := siteList;
        StoreNodeVal := StoreNodeList;
        siteList := '';
      end if;
      DBMS_OUTPUT.put_line ( 'Updating T_STORE_AREA "'||siteVal||'" to node "'||StoreNodeVal||'".' );
      update T_STORE_AREA 
      set STORE_NODE = StoreNodeVal 
      where SITE=siteVal;
      DBMS_OUTPUT.put_line ( 'T_STORE_AREA: '||SQL%rowcount||' records updated.' );
    end Loop;
  else
    DBMS_OUTPUT.put_line ( 'Skipped for environment "'||'&DbEnv'||'".' );
  end if;
End;
/

prompt .
prompt Vault actions for shared fileservers for '&site' (&replStoreArea ; &replStoreDiscPat)
Begin
  if '&runVaultAct' = 'TRUE' then
    update T_STORE_AREA  
    set STORAGE_AREA = replace(STORAGE_AREA,&replStoreArea), 
        STORE_DISCPATH = replace(STORE_DISCPATH, &replStoreDiscPat) 
    where SITE = '&site';
    DBMS_OUTPUT.put_line ( 'T_STORE_AREA: '||SQL%rowcount||' records updated.' );
    update T_FILE_DAT    
    set STORAGE_AREA = replace(STORAGE_AREA,&replStoreArea) 
    where STORAGE_AREA like '&storeArea%'; 
    DBMS_OUTPUT.put_line ( 'T_FILE_DAT: '||SQL%rowcount||' records updated.' );
    update T_DFM_TAR_ARE 
    set STORAGE_AREA = replace(STORAGE_AREA,&replStoreArea) 
    where STORAGE_AREA like '&storeArea%' 
      and SITE = '&site'; 
   DBMS_OUTPUT.put_line ( 'T_DFM_TAR_ARE: '||SQL%rowcount||' records updated.' );
   else
    DBMS_OUTPUT.put_line ( 'Skipped for environment "'||'&DbEnv'||'".' );
  end if;
End;
/

--AutoVue configuration change
prompt .
prompt Deleting PLM-configuration parameters %PVM% not belonging to these sites: &siteList03
Begin
  if '&runDelPVMCfg' = 'TRUE' then
    delete from T_CFG_DAT 
    where T_CFG_DAT.EDB_ID like '%PVM%' 
      and EDB_ID2 NOT IN ( &siteList03 ) 
      and EDB_ID2 is not null; 
      DBMS_OUTPUT.put_line ( 'T_CFG_DAT: '||SQL%rowcount||' records deleted.' );
  else
    DBMS_OUTPUT.put_line ( 'Skipped for environment "'||'&DbEnv'||'".' );
  end if;
End;
/

prompt .
prompt Updating PLM-configuration parameters by replacing values
declare
 siteList varchar2(2000);
 siteVal varchar2(10);
 searchPatternList varchar2(2000);
 searchPattern varchar2(255);
 replParList varchar2(2000);
 replPar varchar2(255);
 replTrg varchar2(255);
 replSrc varchar2(255);
Begin
  if '&runReplCfgVal' = 'TRUE' then
    siteList := '&siteList04';
    searchPatternList := '&searchPatternList01';
    replParList := '&replParList01';
    while length( siteList ) > 0 Loop
      if  instr ( siteList , ',' ) > 0 then
        siteVal :=  substr ( siteList , 1 , instr ( siteList , ',' ) - 1 );
        siteList := substr ( siteList , instr ( siteList , ',' ) + 1  , length( siteList ) );
        searchPattern :=  substr ( searchPatternList , 1 , instr ( searchPatternList , ',' ) - 1 );
        searchPatternList := substr ( searchPatternList , instr ( searchPatternList , ',' ) + 1  , length( searchPatternList ) );
        replPar := substr ( replParList , 1 , instr ( replParList , ',' ) - 1 );
        replParList := substr ( replParList , instr ( replParList , ',' ) + 1  , length( replParList ) );
      else
        siteVal := siteList;
        siteList := '';
        searchPattern := searchPatternList;
        replPar := replParList;
      end if;
      replTrg := substr ( replPar , 1 , instr ( replPar , '>' ) - 1 );
      replSrc := substr ( replPar , instr ( replPar , '>' ) + 1 , length ( replPar ) );
      DBMS_OUTPUT.put_line ( 'Updating T_CFG_DAT "'||siteVal||'" and "'||searchPattern||'" by replacing "'||replTrg||'" by "'||replSrc||'".' );
      update T_CFG_DAT 
      set EDB_VALUE = replace ( EDB_VALUE , replTrg , replSrc )  
      where instr ( searchPattern , '@'||EDB_ID||'@' ) >  0
        and EDB_ID2 = siteVal; 
      DBMS_OUTPUT.put_line ( 'T_CFG_DAT: '||SQL%rowcount||' records updated.' );
    end Loop;
  else
    DBMS_OUTPUT.put_line ( 'Skipped for environment "'||'&DbEnv'||'".' );
  end if;
end;
/

prompt .
prompt Allowed FMS Paths
declare
 cfgEdbIdList varchar2(2000);
 cfgEdbId varchar2(255);
 cfgEdbValList varchar2(2000);
 cfgEdbVal varchar2(255);
Begin
  if '&runAllowedPath' = 'TRUE' then
    cfgEdbIdList := '&cfgEdbIdList01';
    cfgEdbValList := '&cfgEdbValList01';
    while length( cfgEdbIdList ) > 0 Loop
      if  instr ( cfgEdbIdList , ',' ) > 0 then
        cfgEdbId :=  substr ( cfgEdbIdList , 1 , instr ( cfgEdbIdList , ',' ) - 1 );
        cfgEdbIdList := substr ( cfgEdbIdList , instr ( cfgEdbIdList , ',' ) + 1  , length( cfgEdbIdList ) );
        cfgEdbVal :=  substr ( cfgEdbValList , 1 , instr ( cfgEdbValList , ',' ) - 1 );
        cfgEdbValList := substr ( cfgEdbValList , instr ( cfgEdbValList , ',' ) + 1  , length( cfgEdbValList ) );
      else
        cfgEdbId := cfgEdbIdList;
        cfgEdbIdList := '';
        cfgEdbVal := cfgEdbValList;
        
      end if;
      DBMS_OUTPUT.put_line ( 'Updating T_CFG_DAT "'||cfgEdbId||'" to "'||cfgEdbVal||'".' );
      update T_CFG_DAT
      set EDB_VALUE = cfgEdbVal 
      where EDB_ID = cfgEdbId;
      DBMS_OUTPUT.put_line ( 'T_CFG_DAT: '||SQL%rowcount||' records updated.' );
    end Loop;
  else
    DBMS_OUTPUT.put_line ( 'Skipped for environment "'||'&DbEnv'||'".' );
  end if;
end;
/

prompt .
prompt Disabling site-replication for all sites except: &siteList05
Begin
  if '&runDisableSiteRepl' = 'TRUE' then
    update T_DDM_SIT 
    set SFS_RPL_JOB_MAX = 0, 
        SFS_MAIL_STATE = 'DISABLED' 
    where EDB_ID not in ( &siteList05 );
    DBMS_OUTPUT.put_line ( 'T_DDM_SIT: '||SQL%rowcount||' records updated.' ); 
  else
    DBMS_OUTPUT.put_line ( 'Skipped for environment "'||'&DbEnv'||'".' );    
  end if;
End;
/

prompt .
prompt Update PPO configuration to "&ppoCfgSrv01"
Begin
  if '&runPpoCfg' = 'TRUE' then
    update T_PPO_ASV_SPA 
    set T_PPO_ASV_SPA.SYSPAR_VALUE = '&ppoCfgSrv01'
    where T_PPO_ASV_SPA.C_ID_1 in ( select C_ID
                                    from  T_PPO_ASV
                                    where T_PPO_ASV.DEF_ID = 'SFS-central'
                                  )
      and T_PPO_ASV_SPA.C_ID_2 in ( select C_ID 
                                    from T_PPO_SPA 
                                    where T_PPO_SPA.PAR_NAME = 'PPO_JOB_DIR'
                                   );
    DBMS_OUTPUT.put_line ( 'T_PPO_ASV_SPA: '||SQL%rowcount||' records updated.' ); 
    update T_CFG_DAT 
    set EDB_VALUE = '&ppoCfgSrv01'
    where EDB_ID = 'PPO_JOB_DIR'
      and C_ID = ( select a3.C_ID 
                   from T_CFG_DAT a3    
                   inner join T_CFG_STR a2 on a3.C_ID = a2.c_id_2   
                   inner join T_CFG_DAT a1 on a1.C_ID = a2.C_ID_1   
                   where a1.EDB_ID = 'EDB-FMS-ALLOWED-PATHS'
                     and a3.EDB_ID = 'PPO_JOB_DIR'
              );
    DBMS_OUTPUT.put_line ( 'T_CFG_DAT: '||SQL%rowcount||' records updated.' );
  else
    DBMS_OUTPUT.put_line ( 'Skipped for environment "'||'&DbEnv'||'".' );
  end if;
End;
/
              
--Update export-processes
prompt .
prompt Update export-processes
declare
 siteListSrc varchar2(2000);
 siteListTrg varchar2(2000);
 siteValSrc varchar2(10);
 siteValTrg varchar2(10); 
Begin
  if '&runExpProc' = 'TRUE' then
    DBMS_OUTPUT.put_line ( 'Updating SFS_PRC_CITY.OUTPUT_DIR to prefix "&dropLocPrFx01".' );
    update SFS_PRC_CITY 
    set OUTPUT_DIR = '&dropLocPrFx01' || OUTPUT_DIR 
    where OUTPUT_DIR not like '&dropLocPrFx01%';
    DBMS_OUTPUT.put_line ( 'SFS_PRC_CITY: '||SQL%rowcount||' records updated.' );
    
    DBMS_OUTPUT.put_line ( 'Updating SFS_PRC_CITY.DSF_SERVER_REMOTE to value "\\dc1sr2063\PLMview\..." for PDFPRINT.' );
    update ( select pc.DSF_SERVER_REMOTE, 
             cit.PHYSICAL_LOC  
             from SFS_PRC_CITY pc, 
                  T_CITY_DAT cit  
             where pc.C_ID_2 = cit.C_ID  
               and pc.C_ID_1 in ( select C_ID 
                                  from T_EXP_PRC 
                                  where PRC_ID_PLM = 'PDFPRINT'
                                 ) and cit.PHYSICAL_LOC not in ( &expProcSiteList01 ) 
           ) export_loc 
    set export_loc.DSF_SERVER_REMOTE = '\\dc1sr2063\PLMview\' || export_loc.PHYSICAL_LOC;
    DBMS_OUTPUT.put_line ( 'SFS_PRC_CITY: '||SQL%rowcount||' records updated.' );
    
    DBMS_OUTPUT.put_line ( 'Correcting SFS_PRC_CITY.PLOT_SITE to value "dc1" for "PDFPRINTPICKUP" .' );
    update SFS_PRC_CITY 
    set DSF_SERVER_REMOTE = '\\dc1sr2063\PLMviewCentral\DC1' 
    where C_ID_1 in ( select C_ID 
                      from T_EXP_PRC 
                      where PRC_ID_PLM = 'PDFPRINTPICKUP'
                    ) 
      and C_ID_2 in ( select C_ID 
                      from T_CITY_DAT 
                      where PHYSICAL_LOC not in ( &expProcSiteList01 ) 
                    );
     DBMS_OUTPUT.put_line ( 'SFS_PRC_CITY: '||SQL%rowcount||' records updated.' );
                   
     DBMS_OUTPUT.put_line ( 'Updating SFS_PRC_CITY.PLOT_SITE to value "dc1" for CONVERT*, IGES* and EXPORT_NATIVE(ACAD).' );
     update ( select pc.DSF_SERVER_REMOTE, 
                     cit.PHYSICAL_LOC, 
                     pc.PLOT_SITE  
              from SFS_PRC_CITY pc, 
                   T_CITY_DAT cit 
              where pc.C_ID_2 = cit.C_ID  
                and pc.C_ID_1 IN ( select C_ID 
                                   from T_EXP_PRC 
                                   where ( PRC_ID_PLM like 'CONVERT%'
                                          or PRC_ID_PLM like 'IGES%'  
                                          or ( PRC_ID_PLM = 'EXPORT_NATIVE'
                                               and TOOL = 'ACAD'
                                              ) 
                                         ) 
                                     and cit.PHYSICAL_LOC not in ( &expProcSiteList01 ) 
                                   ) 
               ) export_loc 
    set export_loc.DSF_SERVER_REMOTE = '\\dc1sr2063\PLMview\' || export_loc.PHYSICAL_LOC , 
        export_loc.PLOT_SITE = 'dc1';
    DBMS_OUTPUT.put_line ( 'SFS_PRC_CITY: '||SQL%rowcount||' records updated.' );
    
    DBMS_OUTPUT.put_line ( 'Correcting SFS_PRC_CITY.PLOT_SITE to value "&expProcGrbCorrect".' );
    update ( select pc.DSF_SERVER_REMOTE, 
                    cit.PHYSICAL_LOC, 
                    pc.PLOT_SITE  
             from SFS_PRC_CITY pc, 
                  T_CITY_DAT cit 
             where pc.C_ID_2 = cit.C_ID  
               and pc.C_ID_1 in ( select C_ID 
                                  from T_EXP_PRC 
                                  where ( ( PRC_ID_PLM like 'CONVERT%' 
                                            or PRC_ID_PLM like 'IGES%'
                                           ) 
                                          and TOOL not in ('INVMOD', 'INVDRW', 'PROEM', 'PROED') 
                                        ) 
                                 )
               and cit.PHYSICAL_LOC = 'GRB' 
            ) export_loc 
     set export_loc.PLOT_SITE = '&expProcGrbCorrect';
     DBMS_OUTPUT.put_line ( 'SFS_PRC_CITY: '||SQL%rowcount||' records updated.' );
      
     DBMS_OUTPUT.put_line ( 'Updating SFS_PRC_CITY.DSF_SERVER_REMOTE to value "\\dc1sr2063\PLMview\..." for ABC_EXPORT and MWO-EXPORT.' );
     update ( select pc.DSF_SERVER_REMOTE, 
                     cit.PHYSICAL_LOC  
              from SFS_PRC_CITY pc, 
                   T_CITY_DAT cit  
              where pc.C_ID_2 = cit.C_ID  
                and pc.C_ID_1 in ( select C_ID 
                                   from T_EXP_PRC 
                                   where PRC_ID_PLM = 'ABC_EXPORT' 
                                      or PRC_ID_PLM = 'MWO-EXPORT'
                                  ) 
                and cit.PHYSICAL_LOC not in ( &expProcSiteList02  )
              ) export_loc              
     set export_loc.DSF_SERVER_REMOTE = '\\dc1sr2063\PLMview\' || export_loc.PHYSICAL_LOC;
     DBMS_OUTPUT.put_line ( 'SFS_PRC_CITY: '||SQL%rowcount||' records updated.' );
     
     siteListSrc := '&expProcSiteList03';
     siteListTrg := '&expProcSiteList04';
     while length( siteListSrc ) > 0 Loop
      if  instr ( siteListSrc , ',' ) > 0 then
        siteValSrc :=  substr ( siteListSrc , 1 , instr ( siteListSrc , ',' ) - 1 );
        siteListSrc := substr ( siteListSrc , instr ( siteListSrc , ',' ) + 1  , length( siteListSrc ) );
        siteValTrg :=  substr ( siteListTrg , 1 , instr ( siteListTrg , ',' ) - 1 );
        siteListTrg := substr ( siteListTrg , instr ( siteListTrg , ',' ) + 1  , length( siteListTrg ) );
      else
        siteValSrc := siteListSrc;
        siteValTrg := siteListTrg;
        siteListSrc := '';
      end if; 
      DBMS_OUTPUT.put_line ( 'Updating SFS_PRC_CITY.PLOT_SITE "'||siteValSrc||'" to value "'||siteValTrg||'".' );
      update ( select pc.DSF_SERVER_REMOTE, 
                      cit.PHYSICAL_LOC, 
                      pc.PLOT_SITE  
               from SFS_PRC_CITY pc, 
                    T_CITY_DAT cit 
               where pc.C_ID_2 = cit.C_ID  
                 and pc.C_ID_1 in ( select C_ID 
                                    from T_EXP_PRC 
                                    where PRC_ID_PLM in  ( 'CREATE-DXF', 'CREATE-PDF', 'CREATE-THUMBNAIL', 'CREATE-THUMBNAIL-ART', 'REFILE', 'RENAME', 'SAVE', 'CREATE-DXF-WHOLE' )
                                  )   and cit.PHYSICAL_LOC = siteValSrc 
              ) export_loc 
      set export_loc.PLOT_SITE = siteValTrg;
      DBMS_OUTPUT.put_line ( 'SFS_PRC_CITY: '||SQL%rowcount||' records updated.' );
    end loop;
  else
    DBMS_OUTPUT.put_line ( 'Skipped for environment "'||'&DbEnv'||'".' );
  end if;
End;
/

prompt .
prompt Update Creo norm models' location
Begin 
  if '&runCreoNrmModLoc' = 'TRUE' then
     update T_DOC_DAT 
     set CAX_FIL_PATH = '\library-PLM_QS' || substr(CAX_FIL_PATH, 9) 
     where DOC_TYPE = 'PROEM' 
       and CAX_FIL_DISC = 'P:' 
       and substr(lower(CAX_FIL_PATH), 1, 8) = '\library'
       and substr(lower(CAX_FIL_PATH), 1, 15) != lower('\library-PLM_QS');
     DBMS_OUTPUT.put_line ( 'T_DOC_DAT: '||SQL%rowcount||' records updated.' );
     update T_DOC_DAT 
     set CAX_FIL_OLD_PATH  = 'P:\Library-PLM_QS' 
     where doc_type = 'PROEM' 
       and CAX_FIL_OLD_PATH = 'P:\Library';
     DBMS_OUTPUT.put_line ( 'T_DOC_DAT: '||SQL%rowcount||' records updated.' );
     update T_DEFAULT 
     set C_VALUE = 'P:\Library-PLM_QS' 
     where C_NAME = 'SFS-CREO-LOC-LOC'; 
     DBMS_OUTPUT.put_line ( 'T_DOC_DAT: '||SQL%rowcount||' records updated.' );
   else
    DBMS_OUTPUT.put_line ( 'Skipped for environment "'||'&DbEnv'||'".' );
  end if;
End;
/  

--Changes of e-mail addresses
prompt .
prompt Changes of e-mail-sender information
Begin
  if '&runEMailAddress' = 'TRUE' then
    update T_PRS_DAT 
    set S_EMAIL = 'itsupport.plm@marel.com';
    DBMS_OUTPUT.put_line ( 'T_PRS_DAT: '||SQL%rowcount||' records updated to itsupport.plm@marel.com.' );
    update T_CFG_DAT 
    set EDB_VALUE = 'itsupport.plm@marel.com' 
    where C_ID in ( select c2.C_ID 
                    from T_CFG_DAT c1, 
                         T_CFG_STR cs, 
                         T_CFG_DAT c2 
                    where c1.C_ID = cs.C_ID_1 
                      and cs.C_ID_2 = c2.c_id 
                      and c1.EDB_ID = 'SFS-MAIL-ADDRESS' 
                      and c2.EDB_ID <> 'SFS-MAIL-MAILFROM'
                  );
    DBMS_OUTPUT.put_line ( 'T_CFG_DAT: '||SQL%rowcount||' records updated to itsupport.plm@marel.com.' );
    update T_CFG_DAT 
    set EDB_VALUE = 'itsupport.plm.'||lower('&DbEnv')||'@marel.com' 
    where C_ID in ( select c2.C_ID 
                    from T_CFG_DAT c1, 
                         T_CFG_STR cs, 
                         T_CFG_DAT c2 
                    where c1.C_ID = cs.C_ID_1 
                      and cs.C_ID_2 = c2.C_ID 
                      and c1.EDB_ID = 'SFS-MAIL-ADDRESS' 
                      and c2.EDB_ID = 'SFS-MAIL-MAILFROM'
                  );
    DBMS_OUTPUT.put_line ( 'T_CFG_DAT: '||SQL%rowcount||' records updated to itsupport.plm.'||lower('&DbEnv')||'@marel.com.' );    
  else
    DBMS_OUTPUT.put_line ( 'Skipped for environment "'||'&DbEnv'||'".' );
  end if;
End;
/

prompt .
prompt Changes of user accounts
Begin
  if '&runUsers' = 'TRUE' then
    update T_USER set C_DISABLED = 'y' where T_USER.C_IC in (
        select u.c_IC from T_USER u, T_USERMAP m, T_USR_MAP um
        where u.c_id = um.c_id_1 and m.c_id = um.c_id_2
    );
    DBMS_OUTPUT.put_line ( 'T_USER: '||SQL%rowcount||' users disabled.' );
    update T_USER set C_DISABLED = 'n' 
    where T_USER.C_IC in (
    select u.c_IC from T_USER u, T_USERMAP m, T_USR_MAP um
    where u.c_id = um.c_id_1 and m.c_id = um.c_id_2 and (
        u.c_name IN (&enableUsers)
    ));
    DBMS_OUTPUT.put_line ( 'T_USER: '||SQL%rowcount||' users enabled.' );
  else
    DBMS_OUTPUT.put_line ( 'Skipped for environment "'||'&DbEnv'||'".' );
  end if;
End;
/

prompt .
prompt Enabling of user groups
Begin
  if '&runEnableUserGroups' = 'TRUE' then
    update T_USER set C_DISABLED = 'n' 
    where T_USER.C_IC in (
    select u.c_IC from T_USER u, T_USERMAP m, T_USR_MAP um
    where u.c_id = um.c_id_1 and m.c_id = um.c_id_2 and C_DISABLED = 'y' and
    u.SFS_INACT_DESCR != 'Inactive' and  u.SFS_INACT_DESCR != 'Offboarded'
    );
    DBMS_OUTPUT.put_line ( 'T_USER: '||SQL%rowcount||' disabled group users enabled.' );
  else
    DBMS_OUTPUT.put_line ( 'Skipped for environment "'||'&DbEnv'||'".' );
  end if;
End;
/

prompt .
prompt Enabling of PLM test users beginning with TST_
Begin
  if '&runEnableTST_Users' = 'TRUE' then
    update T_USER set C_DISABLED = 'n',  C_PWD_NAM = 'TK3IE74SSVNF7OD5KTORJOOKP47I113CDMD4KV454UJT5KC1944BGFS18H1F9QA2E7A4HA9O29DDV7AKO7ODIAFSN0B4NDGOAHGVKB', C_PWD_ENC = 'SHA-512'
    where T_USER.c_name like 'TST_%'
	and C_DISABLED = 'y';
    DBMS_OUTPUT.put_line ( 'T_USER: '||SQL%rowcount||' disabled PLM test users beginning with TST_ enabled.' );
  else
    DBMS_OUTPUT.put_line ( 'Skipped for environment "'||'&DbEnv'||'".' );
  end if;
End;
/

--Changes TRACK URL
prompt .
prompt Changes of TRACK URL parameter
Begin
  if '&runTrackUrl' = 'TRUE' then
	 update T_CFG_DAT
     set EDB_VALUE = '&trackUrl'
     where EDB_ID = 'SFS-URL-ECR-TRACK';
	 DBMS_OUTPUT.put_line ( 'T_CFG_DAT: '||SQL%rowcount||' records updated to new TRACK URL ' );    
  else
     DBMS_OUTPUT.put_line ( 'Skipped for environment "'||'&DbEnv'||'".' );
  end if;		
End;
/
--Updating Vault URL
prompt .
prompt Changes of VAULT URL parameter
Begin
  if '&runVaultUrl' = 'TRUE' then
	 update T_CFG_DAT
     set EDB_VALUE = '&vaultUrl'
     where EDB_ID = 'SFS-A2V-VAULT-URL';
	 DBMS_OUTPUT.put_line ( 'T_CFG_DAT: '||SQL%rowcount||' records updated to new VAULT URL ' );    
  else
     DBMS_OUTPUT.put_line ( 'Skipped for environment "'||'&DbEnv'||'".' );
  end if;		
End;
/
commit;

--make sure the db-procedure delSiteFromEnvironment exists
@"&SCRIPT_PATH\delSiteFromEnvironment.sql"
prompt .
prompt Execute the procedure delSiteFromEnvironment for each affected site
declare
 siteList varchar2(2000);
 siteVal varchar2(10);
Begin
  if '&runDelSite' = 'TRUE' then
    siteList := '&siteList02';
    while length( siteList ) > 0 Loop
      if  instr ( siteList , ',' ) > 0 then
        siteVal :=  substr ( siteList , 1 , instr ( siteList , ',' ) - 1 );
        siteList := substr ( siteList , instr ( siteList , ',' ) + 1  , length( siteList ) );
      else
        siteVal := siteList;
        siteList := '';
      end if;
      DBMS_OUTPUT.put_line ( 'Executing delSiteFromEnvironment for "'||siteVal||'".' );
      delSiteFromEnvironment ( siteVal ); 
    end Loop;
  else
    DBMS_OUTPUT.put_line ( 'Skipped for environment "'||'&DbEnv'||'".' );
  end if;
End;
/

--Changes for MPS_TASKS Update added for APPPLM-3792
prompt .
prompt CHange the values of TASK_PC and TASK_PROGRAMPARAMS in MPS_TASKS
begin
  if '&runMpsTasksUpd' = 'TRUE' then   
    update MPS_TASKS
    set TASK_PC = '&mpsTaskPc',
        TASK_PROGRAMPARAMS = '&mpsTaskProgParams'
    where TASK_ID = 19;
    DBMS_OUTPUT.put_line ( 'MPS_TASKS: '||SQL%rowcount||' records updated.' );    
  else
    DBMS_OUTPUT.put_line ( 'Skipped for environment "'||'&DbEnv'||'".' );
  end if;
end;
/ 

commit;
spool off
set heading on
set feedback on
