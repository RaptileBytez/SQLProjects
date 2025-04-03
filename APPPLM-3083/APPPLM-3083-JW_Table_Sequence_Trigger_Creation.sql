/**
Initial version of the script to create the AA_T_MASTER_DAT_ECL_APPPLM3083 table, the sequence and the trigger.
Written by Jesco Wurm (ICP) on 19-03-2025
for APPPLM-3083 - As MAREL business we want to exclude some items on the Full item migration to DPH based on non-PLM only rules but based on item number
*/
CREATE TABLE "MARELBLD"."AA_T_MASTER_DAT_ECL_APPPLM3083" 
   ( 
    "EXCL_ID" NUMBER(10),
	"PART_ID" VARCHAR2(40 CHAR) NOT NULL ENABLE, 
    "REASON" VARCHAR2(255 char) NOT NULL ENABLE,
    "PRIO" NUMBER(2) DEFAULT 0
    )
    SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 81920 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "EDB" ;
  
ALTER TABLE AA_T_MASTER_DAT_ECL_APPPLM3083
ADD (
    CONSTRAINT migrate_excl_pk PRIMARY KEY (EXCL_ID)
  );

commit; 

CREATE SEQUENCE migrate_excl_sequence
    START WITH 1
    INCREMENT BY 1;

CREATE OR REPLACE TRIGGER migrate_excl_on_insert
BEFORE INSERT ON AA_T_MASTER_DAT_ECL_APPPLM3083
FOR EACH ROW
DECLARE
  next_val NUMBER;
BEGIN
        SELECT migrate_excl_sequence.nextval
        INTO next_val
        FROM dual;
        :NEW.EXCL_ID := next_val;
END;