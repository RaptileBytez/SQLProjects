--Check if Creo Drwaing masks have the Post Action LGV in place
SELECT 
    C_NAME,
    C_POST_ACTION
FROM
    T_MASK
WHERE 
    (
        C_POST_ACTION LIKE '%DOCUMENT/Doc_post_action%'
    AND 
        (
            C_NAME = 'SFS-DOC-PROED-TLI' --Creo Connector List Mask
            OR C_NAME = 'SFS-DOC-PROED-TFR' --Creo Connector Navigator Mask            
            OR C_NAME = 'SFS-DOC-ACAD-CON-NAV' --ACAD Connector Navigator Mask
            OR C_NAME = 'SFS-DOC-ACAD-CON-TLI' -- ACAD Connector List Mask
            OR C_NAME = 'SFS-DOC-INVDRW-NAV' -- Inventor Connector Navigator Mask
            OR C_NAME = 'SFS-DOC-INVDRW-TLI' -- Inventor Connector List Mask
            OR C_NAME = 'SFS-DOC-SLDDRW-NAV' -- SolidWorks Connector Navigator Mask
            OR C_NAME = 'SFS-DOC-SLDDRW-TLI' -- SolidWorks Connector Navigator Mask
            --OR C_NAME = 'EDB-DOC-SLI' -- Common Document List Mask
            --OR C_NAME = 'EDB-DOC-CFR' -- Common Document Navigator Mask
        )
    )
;