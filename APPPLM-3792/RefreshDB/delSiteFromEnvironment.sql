create or replace procedure delSiteFromEnvironment(p_vault in varchar2)
-- p_vault is the abbreviation for the site e.g. 'nra'
/******************************************************************************
 * del_site_from_database
 * Author: Holger Pertermann 
 * CHG001 : Bvdl 22-05-2017 PLMGRB-113 complete deletion for NRA (PLMGRB-113)
 * Description: Delete file related records for a site
 *****************************************************************************/
IS
-------------
-- CURSORS --
-------------
-- The vault
CURSOR c_store_area
IS
select c_id
  from t_store_area
where nls_upper(site) = nls_upper(p_vault);
r_store_area c_store_area%rowtype;

-- All relations to file for the vault
CURSOR c_fil_store(n_cid2 in number)
IS 
select c_id
       ,c_id_1
  from t_fil_store
where c_id_2 = n_cid2;
r_fil_store c_fil_store%rowtype;

/******************************************************************************
 * VARIABLES
 *****************************************************************************/
n_fil_store_count number:=0;
n_store_count number:=0;


/******************************************************************************
 * Main
 *****************************************************************************/
BEGIN
/* Fetch into the give Store Area (Vault) e.g. nra */
open c_store_area;
loop
fetch c_store_area into r_store_area;
exit when c_store_area%notfound;

  /* Fetch into/through all relation to files for this Vault */
  open c_fil_store(r_store_area.c_id);
  loop
  fetch c_fil_store into r_fil_store;
  exit when c_fil_store%notfound;
  
    /* Here the relation between vault and file can be deleted */
    DELETE from t_fil_store where c_id = r_fil_store.c_id;
--	DBMS_OUTPUT.PUT_LINE('t_fil_store: '||r_fil_store.c_id||'!');
    n_fil_store_count := n_fil_store_count + 1;
	
  end loop;
  close c_fil_store;
  /* CHG001 also remove the vault */
  delete from t_store_area where c_id = r_store_area.c_id;
--  DBMS_OUTPUT.PUT_LINE('t_store_area: '||r_store_area.c_id||'!');
  n_store_count := n_store_count + 1;
  commit;

end loop;
close c_store_area;
/* CHG001 also remove target vaults */
delete from T_DFM_TAR_ARE where nls_upper(SITE) = nls_upper(p_vault);
DBMS_OUTPUT.PUT_LINE('T_DFM_TAR_ARE: '||p_vault||'!');
commit;
/* CHG001 also change the replication config */
update T_DDM_SIT set SFS_RPL_JOB_MAX = 0, SFS_MAIL_STATE='DISABLED' where nls_upper(SITE) = nls_upper(p_vault);
DBMS_OUTPUT.PUT_LINE('T_DDM_SITE: '||p_vault||' disable replication!');
commit;

DBMS_OUTPUT.PUT_LINE('T_FIL_STORE: '||n_fil_store_count||' records deleted for site '||p_vault||'!');
DBMS_OUTPUT.PUT_LINE('T_STORE_AREA: '||n_store_count||' records deleted for site '||p_vault||'!');

END;
