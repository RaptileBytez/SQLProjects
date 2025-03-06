SET echo OFF

SET VERIFY OFF
ACCEPT plugdb PROMPT 'Enter the pluggable database name (eg PLM62DEV) : '
ACCEPT schema PROMPT 'Enter Schema name to connect to as Migration ReadWrite user (eg PLM_QS) : '
ACCEPT username PROMPT 'Username : '
ACCEPT password PROMPT 'Password : ' HIDE


--
-- Creating a role specifically to be used for ReadWrite access to the PLM Schema
-- Create the wanted user with this role
--

ALTER SESSION SET CONTAINER=&plugdb;
EXECUTE DBMS_UTILITY.compile_schema('&schema', compile_all => false);

DECLARE
	v NUMBER(30) DEFAULT 0;
	vRole VARCHAR2(50);
	vSchema VARCHAR(40);
BEGIN
	vRole := '&schema' || '_INTGR_READWRITE_ROLE';
	vSchema := '&schema' || '.';
	SELECT COUNT(1) INTO v from DBA_ROLES WHERE ROLE='vRole';
	IF v=0 THEN
	   BEGIN
		EXECUTE IMMEDIATE 'DROP ROLE ' || vRole;		
		EXECUTE IMMEDIATE 'CREATE ROLE ' || vRole;
		EXECUTE IMMEDIATE 'GRANT CONNECT TO ' || vRole;
		EXECUTE IMMEDIATE 'GRANT CREATE SESSION TO ' || vRole;
		EXECUTE IMMEDIATE 'GRANT ALTER SESSION TO ' || vRole;

		BEGIN
		for X in (select table_name from dba_tables where owner='&schema' AND status = 'VALID' 
			and table_name IN ('T_ERP_ECO','T_ERP_ECO_ITM','T_ERP_ECO_BOM','T_ERP_ECO_DOC','T_ERP_ECO_IDR')
			order by table_name asc)
		loop
			EXECUTE IMMEDIATE 'GRANT SELECT ON ' || vSchema || X.TABLE_NAME || ' TO ' || vRole;
			EXECUTE IMMEDIATE 'GRANT UPDATE ON ' || vSchema || X.TABLE_NAME || ' TO ' || vRole;
		end loop;
		END;
	   END;
	   BEGIN
		   EXECUTE IMMEDIATE 'GRANT SELECT ON ' || vSchema || 'V_PLM_DPH_ITEM' || ' TO ' || vRole;
		   EXECUTE IMMEDIATE 'GRANT SELECT ON ' || vSchema || 'V_PLM_DPH_ALIAS' || ' TO ' || vRole;
	   END;
	   for X in (select view_name from dba_views where owner='&schema' AND status = 'VALID' 
			and view_name IN ('V_SFS_STRS_MASTER_DRW_FIL')
			order by view_name asc)
		loop
			EXECUTE IMMEDIATE 'GRANT SELECT ON ' || vSchema || X.VIEW_NAME || ' TO ' || vRole;
																					  
		end loop;
	END IF;
END;
/


CREATE USER &username
IDENTIFIED BY &password
DEFAULT TABLESPACE "EDB" 
TEMPORARY TABLESPACE "TEMP" 
PROFILE DEFAULT 
QUOTA UNLIMITED ON "EDB" 
QUOTA UNLIMITED ON "EDB_IDX" 
QUOTA UNLIMITED ON "EDB_TMP" 
QUOTA UNLIMITED ON "EDB_TMPIDX" 
QUOTA UNLIMITED ON "EDB_LOB" 
ACCOUNT UNLOCK;
DECLARE
	vRole VARCHAR2(50);
	vUser VARCHAR2(20);
BEGIN
	vRole := '&schema' || '_INTGR_READWRITE_ROLE';
	vUser := '&username';
	EXECUTE IMMEDIATE 'GRANT '|| vRole || ' TO ' || vUser;
END;
/


DECLARE
	vTRG VARCHAR2(50);
	vSchema VARCHAR2(40);
	vUser VARCHAR2(30);
	vSQL VARCHAR2(1000);	
BEGIN
	vTRG := 'TRG_LOGON_' || '&username';	
	vSchema := '&username' || '.SCHEMA'; 
	vUser := '&schema';
	vSQL := 'CREATE OR REPLACE TRIGGER ' || vTRG || ' AFTER LOGON ON ' || vSchema || ' BEGIN
  		EXECUTE IMMEDIATE ''ALTER SESSION SET CURRENT_SCHEMA=' || vUser || '''; END;';
	EXECUTE IMMEDIATE vSQL;
END;
/
quit