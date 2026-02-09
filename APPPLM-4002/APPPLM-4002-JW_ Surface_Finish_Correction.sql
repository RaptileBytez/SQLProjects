-- overview of parts with a different surface finish compared to the related drawing with the same document id
create TABLE
    AA_APPPLM_4002 as
SELECT
    part_id,
    part_version,
    prt.lev_ind prt_lev_ind,
    prt.art_typ,
    prt.c_id prt_cid,
    document_id,
    doc_version,
    drw.lev_ind drw_lev_ind,
    drw.doc_type,
    drw.sheet_no,
    prt.opbh prt_opbh,
    drwp.opbh drw_opbh --PROED
FROM
    t_master_dat prt,
    t_master_doc pd,
    t_doc_dat drw,
    t_doc_proed drwp
WHERE
    prt.c_id = pd.c_id_1
    AND pd.c_id_2 = drw.c_id
    AND drw.c_id = drwp.c_id_2
    AND prt.part_id = drw.document_id
    AND drwp.opbh IS NOT NULL
    AND (
        prt.opbh != drwp.opbh
        OR prt.opbh IS NULL
    )
    AND prt.lev_ind < 260
    AND drw.lev_ind < 260
    AND prt.lev_ind != 160
    AND drw.lev_ind != 160
    AND (
        (
            art_typ = 'A'
            AND prt.part_version = drw.doc_version
        )
        OR art_typ != 'A'
    )
    AND drwp.opbh IN (
        SELECT
            CODE
        FROM
            PMT_OPP
    )
UNION
SELECT
    part_id,
    part_version,
    prt.lev_ind prt_lev_ind,
    prt.art_typ,
    prt.c_id prt_cid,
    document_id,
    doc_version,
    drw.lev_ind drw_lev_ind,
    drw.doc_type,
    drw.sheet_no,
    prt.opbh prt_opbh,
    drwp.opbh drw_opbh -- ACAD
FROM
    t_master_dat prt,
    t_master_doc pd,
    t_doc_dat drw,
    t_doc_acad drwp
WHERE
    prt.c_id = pd.c_id_1
    AND pd.c_id_2 = drw.c_id
    AND drw.c_id = drwp.c_id_2
    AND prt.part_id = drw.document_id
    AND drwp.opbh IS NOT NULL
    AND (
        prt.opbh != drwp.opbh
        OR prt.opbh IS NULL
    )
    AND prt.lev_ind < 260
    AND drw.lev_ind < 260
    AND prt.lev_ind != 160
    AND drw.lev_ind != 160
    AND (
        (
            art_typ = 'A'
            AND prt.part_version = drw.doc_version
        )
        OR art_typ != 'A'
    )
    AND drwp.opbh IN (
        SELECT
            CODE
        FROM
            PMT_OPP
    )
UNION
SELECT
    part_id,
    part_version,
    prt.lev_ind prt_lev_ind,
    prt.art_typ,
    prt.c_id prt_cid,
    document_id,
    doc_version,
    drw.lev_ind drw_lev_ind,
    drw.doc_type,
    drw.sheet_no,
    prt.opbh prt_opbh,
    drwp.surf_fin drw_opbh -- SLDDRW
FROM
    t_master_dat prt,
    t_master_doc pd,
    t_doc_dat drw,
    t_doc_slddrw drwp
WHERE
    prt.c_id = pd.c_id_1
    AND pd.c_id_2 = drw.c_id
    AND drw.c_id = drwp.c_id_2
    AND prt.part_id = drw.document_id
    AND drwp.surf_fin IS NOT NULL
    AND (
        prt.opbh != drwp.surf_fin
        OR prt.opbh IS NULL
    )
    AND prt.lev_ind < 260
    AND drw.lev_ind < 260
    AND prt.lev_ind != 160
    AND drw.lev_ind != 160
    AND (
        (
            art_typ = 'A'
            AND prt.part_version = drw.doc_version
        )
        OR art_typ != 'A'
    )
    AND drwp.surf_fin IN (
        SELECT
            CODE
        FROM
            PMT_OPP
    )
UNION
SELECT
    part_id,
    part_version,
    prt.lev_ind prt_lev_ind,
    prt.art_typ,
    prt.c_id prt_cid,
    document_id,
    doc_version,
    drw.lev_ind drw_lev_ind,
    drw.doc_type,
    drw.sheet_no,
    prt.opbh prt_opbh,
    drwp.surf_fin drw_opbh -- INVDRW
FROM
    t_master_dat prt,
    t_master_doc pd,
    t_doc_dat drw,
    t_doc_invdrw drwp
WHERE
    prt.c_id = pd.c_id_1
    AND pd.c_id_2 = drw.c_id
    AND drw.c_id = drwp.c_id_2
    AND prt.part_id = drw.document_id
    AND drwp.surf_fin IS NOT NULL
    AND (
        prt.opbh != drwp.surf_fin
        OR prt.opbh IS NULL
    )
    AND prt.lev_ind < 260
    AND drw.lev_ind < 260
    AND prt.lev_ind != 160
    AND drw.lev_ind != 160
    AND (
        (
            art_typ = 'A'
            AND prt.part_version = drw.doc_version
        )
        OR art_typ != 'A'
    )
    AND drwp.surf_fin IN (
        SELECT
            CODE
        FROM
            PMT_OPP
    )
ORDER BY
    1,
    2,
    3;

-- add a column RULE
alter table AA_APPPLM_4002
add "RULE" VARCHAR2(120 CHAR);

-- overview of the data
SELECT
    *
FROM
    AA_APPPLM_4002
ORDER BY
    rule,
    part_id,
    part_version;

-- which of these items are listed more than once
SELECT
    part_id,
    part_version,
    count(*)
FROM
    AA_APPPLM_4002
GROUP BY
    part_id,
    part_version
having
    count(*) > 1
ORDER BY
    3 desc;

-- do not process when multiple different values for drw_opbh are found 
SELECT
    t1.part_id,
    t1.part_version,
    t1.prt_opbh,
    t1.drw_opbh,
    t2.drw_opbh
FROM
    AA_APPPLM_4002 t1,
    AA_APPPLM_4002 t2
WHERE
    t1.prt_cid = t2.prt_cid
    AND t1.drw_opbh != t2.drw_opbh
    AND t1.rule IS NULL;

update AA_APPPLM_4002
set
    RULE = 'more values for drw_opbh for same part_cid'
WHERE
    prt_cid IN (
        SELECT
            t1.prt_cid
        FROM
            AA_APPPLM_4002 t1,
            AA_APPPLM_4002 t2
        WHERE
            t1.prt_cid = t2.prt_cid
            AND t1.drw_opbh != t2.drw_opbh
            AND t1.rule IS NULL
    );

-- do not process when the prt_opbh is already in sync with any other drawing related to the item
-- PROED = 0
SELECT
    t1.part_id,
    t1.part_version,
    t1.art_typ,
    t1.prt_opbh,
    t1.drw_opbh,
    t2.opbh
FROM
    AA_APPPLM_4002 t1,
    t_master_doc pd,
    t_doc_dat d2,
    t_doc_proed t2
WHERE
    t1.prt_cid = pd.c_id_1
    AND pd.c_id_2 = d2.c_id
    AND d2.doc_type = t1.doc_type
    AND d2.document_id = t1.document_id
    AND d2.c_id = t2.c_id_2
    AND (
        (
            art_typ = 'A'
            AND t1.part_version = d2.doc_version
        )
        OR art_typ != 'A'
    )
    AND d2.lev_ind < 260
    AND d2.lev_ind != 160
    AND t1.drw_opbh != t2.opbh
    AND t1.prt_opbh = t2.opbh
    AND t1.rule IS NULL;

-- ACAD = 81
SELECT
    t1.part_id,
    t1.part_version,
    t1.art_typ,
    t1.prt_opbh,
    t1.drw_opbh,
    t2.opbh
FROM
    AA_APPPLM_4002 t1,
    t_master_doc pd,
    t_doc_dat d2,
    t_doc_acad t2
WHERE
    t1.prt_cid = pd.c_id_1
    AND pd.c_id_2 = d2.c_id
    AND d2.doc_type = t1.doc_type
    AND d2.document_id = t1.document_id
    AND d2.c_id = t2.c_id_2
    AND (
        (
            art_typ = 'A'
            AND t1.part_version = d2.doc_version
        )
        OR art_typ != 'A'
    )
    AND d2.lev_ind < 260
    AND d2.lev_ind != 160
    AND t1.drw_opbh != t2.opbh
    AND t1.prt_opbh = t2.opbh
    AND t1.rule IS NULL;

update AA_APPPLM_4002
set
    RULE = 'prt_opbh is already in sync with other related drawing'
WHERE
    prt_cid IN (
        SELECT
            t1.prt_cid
        FROM
            AA_APPPLM_4002 t1,
            t_master_doc pd,
            t_doc_dat d2,
            t_doc_acad t2
        WHERE
            t1.prt_cid = pd.c_id_1
            AND pd.c_id_2 = d2.c_id
            AND d2.doc_type = t1.doc_type
            AND d2.document_id = t1.document_id
            AND d2.c_id = t2.c_id_2
            AND (
                (
                    art_typ = 'A'
                    AND t1.part_version = d2.doc_version
                )
                OR art_typ != 'A'
            )
            AND d2.lev_ind < 260
            AND d2.lev_ind != 160
            AND t1.drw_opbh != t2.opbh
            AND t1.prt_opbh = t2.opbh
            AND t1.rule IS NULL
    );

-- SLDDRW = 3
SELECT
    t1.part_id,
    t1.part_version,
    t1.art_typ,
    t1.prt_opbh,
    t1.drw_opbh,
    t2.surf_fin
FROM
    AA_APPPLM_4002 t1,
    t_master_doc pd,
    t_doc_dat d2,
    t_doc_slddrw t2
WHERE
    t1.prt_cid = pd.c_id_1
    AND pd.c_id_2 = d2.c_id
    AND d2.doc_type = t1.doc_type
    AND d2.document_id = t1.document_id
    AND d2.c_id = t2.c_id_2
    AND (
        (
            art_typ = 'A'
            AND t1.part_version = d2.doc_version
        )
        OR art_typ != 'A'
    )
    AND d2.lev_ind < 260
    AND d2.lev_ind != 160
    AND t1.drw_opbh != t2.surf_fin
    AND t1.prt_opbh = t2.surf_fin
    AND t1.rule IS NULL;

update AA_APPPLM_4002
set
    RULE = 'prt_opbh is already in sync with other related drawing'
WHERE
    prt_cid IN (
        SELECT
            t1.prt_cid
        FROM
            AA_APPPLM_4002 t1,
            t_master_doc pd,
            t_doc_dat d2,
            t_doc_slddrw t2
        WHERE
            t1.prt_cid = pd.c_id_1
            AND pd.c_id_2 = d2.c_id
            AND d2.doc_type = t1.doc_type
            AND d2.document_id = t1.document_id
            AND d2.c_id = t2.c_id_2
            AND (
                (
                    art_typ = 'A'
                    AND t1.part_version = d2.doc_version
                )
                OR art_typ != 'A'
            )
            AND d2.lev_ind < 260
            AND d2.lev_ind != 160
            AND t1.drw_opbh != t2.surf_fin
            AND t1.prt_opbh = t2.surf_fin
            AND t1.rule IS NULL
    );

-- INVDRW = 0
SELECT
    t1.part_id,
    t1.part_version,
    t1.art_typ,
    t1.prt_opbh,
    t1.drw_opbh,
    t2.surf_fin
FROM
    AA_APPPLM_4002 t1,
    t_master_doc pd,
    t_doc_dat d2,
    t_doc_invdrw t2
WHERE
    t1.prt_cid = pd.c_id_1
    AND pd.c_id_2 = d2.c_id
    AND d2.doc_type = t1.doc_type
    AND d2.document_id = t1.document_id
    AND d2.c_id = t2.c_id_2
    AND (
        (
            art_typ = 'A'
            AND t1.part_version = d2.doc_version
        )
        OR art_typ != 'A'
    )
    AND d2.lev_ind < 260
    AND d2.lev_ind != 160
    AND t1.drw_opbh != t2.surf_fin
    AND t1.prt_opbh = t2.surf_fin
    AND t1.rule IS NULL;

-- do not process duplicates for different sheet numbers or document_revisions
SELECT
    t1.*,
    t2.doc_version,
    t2.sheet_no
FROM
    AA_APPPLM_4002 t1,
    AA_APPPLM_4002 t2
WHERE
    t1.rule IS NULL
    AND t2.rule IS NULL
    AND t1.prt_cid = t2.prt_cid
    AND t1.drw_opbh = t2.drw_opbh
    AND (
        t1.sheet_no > t2.sheet_no
        OR t1.doc_version > t2.doc_version
        OR (
            t1.doc_version IS NOT NULL
            AND t2.doc_version IS NULL
        )
    );

update AA_APPPLM_4002
set
    RULE = 'multiple same entries'
WHERE
    prt_cid || doc_version || sheet_no IN (
        SELECT
            t1.prt_cid || t1.doc_version || t1.sheet_no
        FROM
            AA_APPPLM_4002 t1,
            AA_APPPLM_4002 t2
        WHERE
            t1.rule IS NULL
            AND t2.rule IS NULL
            AND t1.prt_cid = t2.prt_cid
            AND t1.drw_opbh = t2.drw_opbh
            AND (
                t1.sheet_no > t2.sheet_no
                OR t1.doc_version > t2.doc_version
                OR (
                    t1.doc_version IS NOT NULL
                    AND t2.doc_version IS NULL
                )
            )
    );

commit;

-- overview of the data to be processed
SELECT
    *
FROM
    AA_APPPLM_4002
WHERE
    rule IS NULL
ORDER BY
    part_id,
    part_version;

SELECT
    *
FROM
    AA_APPPLM_4002
WHERE
    rule IS NULL
    AND prt_cid IN (
        SELECT
            prt_cid
        FROM
            AA_APPPLM_4002
        WHERE
            rule IS NULL
        GROUP BY
            prt_cid
        having
            count(*) > 1
    )
ORDER BY
    part_id,
    part_version;

SELECT
    count(*)
FROM
    AA_APPPLM_4002
WHERE
    rule IS NULL;

SELECT
    count(distinct prt_cid)
FROM
    AA_APPPLM_4002
WHERE
    rule IS NULL;

-- Create cursor of t_master_dat objects to process AND process them
DECLARE CURSOR itm IS
SELECT
    prt_cid,
    part_version,
    prt_opbh,
    drw_opbh
FROM
    AA_APPPLM_4002
WHERE
    rule IS NULL;

n_itm_cid NUMBER(10);

v_itm_version VARCHAR2(10);

v_itm_opbh VARCHAR2(12);

v_drw_opbh VARCHAR2(12);

v_memo VARCHAR2(150);

n_count NUMBER(10);

BEGIN n_count := 0;

OPEN itm;

LOOP FETCH itm INTO n_itm_cid,
v_itm_version,
v_itm_opbh,
v_drw_opbh;

EXIT WHEN itm % NOTFOUND;

v_memo := 'Surface Finish is aligned with the related drawing FROM ' || v_itm_opbh || ' to ' || v_drw_opbh;

insert into
    T_MASTER_HIS (
        C_ID, -- tMasterHisCid,
        C_VERSION, -- 1,
        C_LOCK, -- 0,
        C_UIC, -- 1829,
        C_GIC, -- 100,
        C_CRE_DAT, -- sysdate,
        C_UPD_DAT, -- sysdate,
        C_ACC_OGW, -- 'ddd',
        C_ID_1, -- n_itm_cid,
        C_ID_2, -- 0,
        HIST_ID, -- tMasterHisId;
        FUNCTION, -- 'MEMO',
        MODIFY_DATE, -- sysdate,
        MODIFY_NAME, -- 'PLM_MIGRATOR',
        CHANGE_REV, -- null,
        CHANGE_STATUS, -- null,
        ACTION, -- null,
        CHANGE_NR, -- v_itm_version,
        STUKNR, -- null,
        PLOT_FLAG, -- null, 
        CHK_BY, -- null,
        MEMO, -- 'PLL changed FROM xxx-xxx to xxx-xxx.',
        CHK_NAME, -- null,
        OLD_LEV_IND, -- null,
        NEW_LEV_IND, -- null,
        ECO_REF, -- null,
        STEP_SECURITY -- null
    )
values
    (
        T_MASTER_HIS_SEQ.nextval, --C_ID         
        1, --C_VERSION    
        0, --C_LOCK       
        1829, --C_UIC        
        100, --C_GIC        
        sysdate, --C_CRE_DAT    
        sysdate, --C_UPD_DAT    
        'ddd', --C_ACC_OGW    
        n_itm_cid, --C_ID_1       
        0, --C_ID_2       
        T_MASTER_HIS_HSEQ.nextval, --HIST_ID 
        'MEMO', --FUNCTION     
        sysdate, --MODIFY_DATE  
        'PLM_MIGRATOR', --MODIFY_NAME  
        null, --CHANGE_REV   
        null, --CHANGE_STATUS
        null, --ACTION       
        v_itm_version, --CHANGE_NR    
        null, --STUKNR       
        null, --PLOT_FLAG    
        null, --CHK_BY       
        v_memo, --MEMO         
        null, --CHK_NAME     
        null, --OLD_LEV_IND  
        null, --NEW_LEV_IND  
        null, --ECO_REF      
        null
    );

--STEP_SECURITY
update T_MASTER_DAT
set
    opbh = v_drw_opbh
WHERE
    c_id = n_itm_cid;

n_count := n_count + 1;

IF MOD(n_count, 200) = 0 THEN COMMIT;

END IF;

END
LOOP;

COMMIT;

CLOSE itm;

END;

/
-- verify the results
SELECT
    count(*)
FROM
    t_master_his
WHERE
    memo like 'Surface Finish is aligned with the related drawing FROM%';

SELECT
    count(*)
FROM
    t_master_dat prt,
    AA_APPPLM_4002 t1
WHERE
    prt.c_id = t1.prt_cid
    AND t1.rule IS NULL
    AND prt.opbh = t1.drw_opbh;

SELECT
    doc_type,
    art_typ,
    count(*)
FROM
    AA_APPPLM_4002
GROUP BY
    doc_type,
    art_typ
ORDER BY
    1,
    2;

SELECT
    prt.part_id,
    prt.part_version,
    prt.lev_ind prt_lev_ind,
    prt.art_typ,
    prt.c_id prt_cid,
    drw.document_id,
    drw.doc_version,
    drw.lev_ind drw_lev_ind,
    drw.doc_type,
    drw.sheet_no,
    prt.opbh prt_opbh,
    drwp.opbh drw_opbh,
    t1.rule --PROED
FROM
    t_master_dat prt,
    t_master_doc pd,
    t_doc_dat drw,
    t_doc_proed drwp,
    AA_APPPLM_4002 t1
WHERE
    prt.c_id = pd.c_id_1
    AND pd.c_id_2 = drw.c_id
    AND drw.c_id = drwp.c_id_2
    AND prt.part_id = drw.document_id
    AND drwp.opbh IS NOT NULL
    AND (
        prt.opbh != drwp.opbh
        OR prt.opbh IS NULL
    )
    AND prt.c_id = t1.prt_cid (+)
    AND prt.lev_ind < 260
    AND drw.lev_ind < 260
    AND prt.lev_ind != 160
    AND drw.lev_ind != 160
    AND (
        (
            prt.art_typ = 'A'
            AND prt.part_version = drw.doc_version
        )
        OR prt.art_typ != 'A'
    )
    AND drwp.opbh IN (
        SELECT
            CODE
        FROM
            PMT_OPP
    )
UNION
SELECT
    prt.part_id,
    prt.part_version,
    prt.lev_ind prt_lev_ind,
    prt.art_typ,
    prt.c_id prt_cid,
    drw.document_id,
    drw.doc_version,
    drw.lev_ind drw_lev_ind,
    drw.doc_type,
    drw.sheet_no,
    prt.opbh prt_opbh,
    drwp.opbh drw_opbh,
    t1.rule -- ACAD
FROM
    t_master_dat prt,
    t_master_doc pd,
    t_doc_dat drw,
    t_doc_acad drwp,
    AA_APPPLM_4002 t1
WHERE
    prt.c_id = pd.c_id_1
    AND pd.c_id_2 = drw.c_id
    AND drw.c_id = drwp.c_id_2
    AND prt.part_id = drw.document_id
    AND drwp.opbh IS NOT NULL
    AND (
        prt.opbh != drwp.opbh
        OR prt.opbh IS NULL
    )
    AND prt.c_id = t1.prt_cid (+)
    AND prt.lev_ind < 260
    AND drw.lev_ind < 260
    AND prt.lev_ind != 160
    AND drw.lev_ind != 160
    AND (
        (
            prt.art_typ = 'A'
            AND prt.part_version = drw.doc_version
        )
        OR prt.art_typ != 'A'
    )
    AND drwp.opbh IN (
        SELECT
            CODE
        FROM
            PMT_OPP
    )
UNION
SELECT
    prt.part_id,
    prt.part_version,
    prt.lev_ind prt_lev_ind,
    prt.art_typ,
    prt.c_id prt_cid,
    drw.document_id,
    drw.doc_version,
    drw.lev_ind drw_lev_ind,
    drw.doc_type,
    drw.sheet_no,
    prt.opbh prt_opbh,
    drwp.surf_fin drw_opbh,
    t1.rule -- SLDDRW
FROM
    t_master_dat prt,
    t_master_doc pd,
    t_doc_dat drw,
    t_doc_slddrw drwp,
    AA_APPPLM_4002 t1
WHERE
    prt.c_id = pd.c_id_1
    AND pd.c_id_2 = drw.c_id
    AND drw.c_id = drwp.c_id_2
    AND prt.part_id = drw.document_id
    AND drwp.surf_fin IS NOT NULL
    AND (
        prt.opbh != drwp.surf_fin
        OR prt.opbh IS NULL
    )
    AND prt.c_id = t1.prt_cid (+)
    AND prt.lev_ind < 260
    AND drw.lev_ind < 260
    AND prt.lev_ind != 160
    AND drw.lev_ind != 160
    AND (
        (
            prt.art_typ = 'A'
            AND prt.part_version = drw.doc_version
        )
        OR prt.art_typ != 'A'
    )
    AND drwp.surf_fin IN (
        SELECT
            CODE
        FROM
            PMT_OPP
    )
UNION
SELECT
    prt.part_id,
    prt.part_version,
    prt.lev_ind prt_lev_ind,
    prt.art_typ,
    prt.c_id prt_cid,
    drw.document_id,
    drw.doc_version,
    drw.lev_ind drw_lev_ind,
    drw.doc_type,
    drw.sheet_no,
    prt.opbh prt_opbh,
    drwp.surf_fin drw_opbh,
    t1.rule -- INVDRW
FROM
    t_master_dat prt,
    t_master_doc pd,
    t_doc_dat drw,
    t_doc_invdrw drwp,
    AA_APPPLM_4002 t1
WHERE
    prt.c_id = pd.c_id_1
    AND pd.c_id_2 = drw.c_id
    AND drw.c_id = drwp.c_id_2
    AND prt.part_id = drw.document_id
    AND drwp.surf_fin IS NOT NULL
    AND (
        prt.opbh != drwp.surf_fin
        OR prt.opbh IS NULL
    )
    AND prt.c_id = t1.prt_cid (+)
    AND prt.lev_ind < 260
    AND drw.lev_ind < 260
    AND prt.lev_ind != 160
    AND drw.lev_ind != 160
    AND (
        (
            prt.art_typ = 'A'
            AND prt.part_version = drw.doc_version
        )
        OR prt.art_typ != 'A'
    )
    AND drwp.surf_fin IN (
        SELECT
            CODE
        FROM
            PMT_OPP
    )
ORDER BY
    1,
    2,
    3;