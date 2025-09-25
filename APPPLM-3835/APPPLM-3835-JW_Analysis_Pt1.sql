WITH spare_counts AS (
    SELECT
        str.c_id_2                 AS part_c_id,
        COUNT(DISTINCT str.c_id_1) AS spare_count
    FROM
        t_master_str str
    WHERE
        str.spare = 'S'
    GROUP BY
        str.c_id_2
), latest_memo AS (
    SELECT
        prt.c_id,
        prt.part_id,
        prt.part_version,
        his.modify_name AS his_modify_name,
        his.memo,
        his.modify_date,
        ROW_NUMBER()
        OVER(PARTITION BY prt.c_id
             ORDER BY
                 his.modify_date DESC
        )               AS rn
    FROM
             t_master_dat prt
        INNER JOIN t_master_his his ON prt.c_id = his.c_id_1
    WHERE
            prt.cur_flag = 'y'
        AND prt.part_subtype = 'NRM'
        AND his.function = 'MEMO'
        AND his.memo LIKE 'Spare Part Flag%'
), latest_itm AS (
    SELECT
        itm.item_number,
        itm.revision,
        itm.eco_number,
        itm.job_status,
        itm.eco_itm_intgr_job_status,
        itm.plm_item_spare,
        ROW_NUMBER()
        OVER(PARTITION BY itm.item_number, itm.revision
             ORDER BY
                 itm.c_cre_dat DESC
        ) AS rn
    FROM
        t_erp_eco_itm itm
)
SELECT
    prt.c_id,
    prt.part_id,
    prt.part_version,
    prt.lev_ind,
    prt.spare              AS spare_part_flag,
    nvl(sc.spare_count, 0) AS spare_count,
    lm.memo,
    lm.modify_date,
    lm.his_modify_name,
    li.eco_number,
    li.job_status,
    li.eco_itm_intgr_job_status,
    li.plm_item_spare
FROM
    t_master_dat prt
    LEFT JOIN spare_counts sc ON sc.part_c_id = prt.c_id
    LEFT JOIN latest_memo  lm ON lm.c_id = prt.c_id
                                AND lm.rn = 1
    LEFT JOIN latest_itm   li ON prt.part_id = li.item_number
                               AND nvl(prt.part_version, '-') = nvl(li.revision, '-')
                               AND li.rn = 1
WHERE
        prt.cur_flag = 'y'
    AND prt.part_subtype = 'NRM'
    AND prt.spare = 'y'
    AND spare_count > 0
  -- AND prt.C_ID = 1938660540
ORDER BY
    spare_count ASC,
    prt.part_id ASC;