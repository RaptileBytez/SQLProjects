--set execution-controls
define runAllEnvironmentGenericChange = TRUE
define runStorageNodeChange = TRUE
define runVaultAct = FALSE
define runDelPVMCfg = TRUE
define runReplCfgVal = TRUE
define runAllowedPath = TRUE
define runDisableSiteRepl = TRUE
define runPpoCfg = TRUE
define runExpProc = TRUE
define runCreoNrmModLoc = TRUE
define runEMailAddress = TRUE
define runUsers = FALSE
define runEnableUserGroups = TRUE
define runEnableTST_Users = TRUE
define runDelSite = TRUE
define runTrackUrl = TRUE
define runVaultUrl = TRUE
define runMpsTasksUpd = TRUE

--set IP-addresses of storage-nodes site-specific:
--Value-set for T_STORE_AREA-update
define siteList01 = pmt,gam,grb,dsm,dc1
define StoreNodeList = 10.1.33.190,10.32.112.136,10.8.2.134,10.32.121.210,10.99.25.74

--prompt Vault actions for shared fileservers (skipped for QS)
define replStoreArea = "'',''"
define replStoreDiscPat = "'',''"
define storeArea = ''
define site = ''

--AutoVue configuration change
--Deleting PLM-configuration parameters %PVM% not belonging to these sites: &siteList03
define siteList03 = "'dsm', 'gam', 'grb', 'pmt', 'dc1'"

--prompt Updating PLM-configuration parameters by replacing values
define siteList04 = dc1,pmt,dsm,gam,grb
define helper = @EDB-PVM-AV-DMS@EDB-PVM-AV-PROXY@
define searchPatternList01 = @EDB-PVM-AV-DMS@EDB-PVM-AV-PROXY@,&helper,&helper,&helper,&helper
define replParList01 = dc1sr0151>dc1sr0187,boxsr0466>boxsr0188,dsmsr0202>dsmsr0201,gaisr0154>gaisr0189,grbsr0153>grbsr0132

--Allowed FMS Paths
define cfgEdbIdList01 = SFS-ERP-PRC,SFS-ERP-NRA,SFS-ERP-DAX,SFS-HPPLOT-CHKOUT-PATH 
define cfgEdbValList01 = \\azbrssr0003\PLM$\TEST\QS,\\NRASR0004\PLMVIEW\ERPTEST,\\DC1SR1125\PLM_TEST\QS,\\DC1SR0079\plmdata\plm_qs_6210\HP_PLOT

--Disabling site-replication (exclusion list)
define siteList05 = "'DC1', 'PMT', 'GAM', 'DSM', 'GRB'"

--Update PPO configuration 
define ppoCfgSrv01 = \\DC1SR3070\Input_PLM\PPO

--Update export-processes
define dropLocPrFx01 = QS\
define expProcSiteList01 = "'DC1','BOX','DSM','GAI','GRB'"
define expProcSiteList02 = "'DC1'"
define expProcSiteList03 = GRB,COL,AAR,STO,EIN,PRC
define expProcSiteList04 = grb,dc1,dc1,dc1,dc1,dc1
define expProcGrbCorrect = grb

--Update users
define enableUsers = "'I_VD_BROEK','M_DAMEN'"

--Execute procedures to remove all references to not existing sites
define siteList02 = aar,bra,col,gup,sto,az1

--Update Track URL
define trackUrl = 'https://marelholdingbv-acc.outsystemsenterprise.com/track/ConcernDetail.aspx?ConcernId='

--Update Vault URL
define vaultUrl = 'http://DC1PB7108:23475/api/Command/ --noproxy DC1PB7108'

--Update MPS_TASKS values
define mpsTaskPc = 'DC1PB7134'
define mpsTaskProgParams = '/plmsite=PLM62QS'