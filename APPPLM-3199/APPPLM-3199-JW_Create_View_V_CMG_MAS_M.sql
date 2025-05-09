  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_CMG_MAS_M" ("C_ID", "C_VERSION", "C_LOCK", "C_UIC", "C_GIC", "C_CRE_DAT", "C_UPD_DAT", "C_ACC_OGW", "PART_ID", "PART_VERSION", "PART_REVISION", "ART_TYP", "PMT_STBN_ENG", "FREE_NAME", "SFS_TITLE_SUB", "PART_NAME_ENG", "PART_NAME_GER", "PART_NAME_FRA", "ITEM_TYPE", "UNIT", "BOM_FLAG", "AGG_FLAG", "CHK_NAME", "LEV_IND", "TYP", "VAR_NUM", "VAL_FROM", "VAL_UNTIL", "CUR_FLAG", "MATERIAL", "DTS_REF", "ZEICHNR", "VOLUMEN", "FLAECHE", "GEWICHT", "RES_REF", "NTM_REF", "STEP_SOURCE", "STEP_DESCR", "EXTERNAL_ITEM", "EDB_ICON", "EDB_ID", "CAGE_CODE", "CMG_CTRL", "SNO_FLAG", "TCICTRL", "UITVOERING", "MCODE", "MOTK", "PART_SUBTYPE", "NORM_TYPE", "SERVICE", "ART_BLOB", "ART_BLOB_NAME", "SFS_SERV_BOM", "SPARE") AS 
  SELECT
        t_master_dat.c_id               "C_ID",
        t_master_dat.c_version          "C_VERSION",
        t_master_dat.c_lock             "C_LOCK",
        t_master_dat.c_uic              "C_UIC",
        t_master_dat.c_gic              "C_GIC",
        t_master_dat.c_cre_dat          "C_CRE_DAT",
        t_master_dat.c_upd_dat          "C_UPD_DAT",
        t_master_dat.c_acc_ogw          "C_ACC_OGW",
        "PART_ID",
        "PART_VERSION",
        "PART_REVISION",
        t_master_dat.art_typ            "ART_TYP",
        t_master_dat.pmt_stbn_eng       "PMT_STBN_ENG",
        t_master_dat.free_name          "FREE_NAME",
        t_master_dat.pmt_stbn_eng
        || ' '
        || t_master_dat.free_name "SFS_TITLE_SUB",
        "PART_NAME_ENG",
        "PART_NAME_GER",
        "PART_NAME_FRA",
        "ITEM_TYPE",
        "UNIT",
        "BOM_FLAG",
        "AGG_FLAG",
        "CHK_NAME",
        "LEV_IND",
        "TYP",
        "VAR_NUM",
        "VAL_FROM",
        "VAL_UNTIL",
        "CUR_FLAG",
        "MATERIAL",
        "DTS_REF",
        "ZEICHNR",
        "VOLUMEN",
        "FLAECHE",
        "GEWICHT",
        "RES_REF",
        "NTM_REF",
        "STEP_SOURCE",
        "STEP_DESCR",
        "EXTERNAL_ITEM",
        "EDB_ICON",
        "EDB_ID",
        "CAGE_CODE",
        "CMG_CTRL",
        "SNO_FLAG",
        "TCICTRL",
        "UITVOERING",
        "MCODE",
        "MOTK",
        "PART_SUBTYPE",
        "NORM_TYPE",
        "SERVICE",
        --v_cpa_art_dat.step_int_id_ref   "ALIAS_REF", 					--> APPPLM-1310 
        --v_cpa_art_dat.alias_id          "ALIAS_ID",  					--> APPPLM-1310
        "ART_BLOB",
        "ART_BLOB_NAME",
        "SFS_SERV_BOM",
        "SPARE"                                           --added to view by APPPLM3199
    FROM
        t_master_dat;

commit;