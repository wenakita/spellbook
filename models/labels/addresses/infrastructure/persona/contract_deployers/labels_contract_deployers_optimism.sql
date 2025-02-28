{{
    config(
        alias = alias('contract_deployers_optimism'),
        post_hook='{{ expose_spells(\'["optimism"]\',
                                    "sector",
                                    "labels",
                                    \'["hildobby", "hosuke"]\') }}'
    )
}}

SELECT distinct 'optimism'           AS blockchain
              , creation.`from`      AS address
              , 'Contract Deployer'  AS name
              , 'infrastructure'     AS category
              , 'hildobby'           AS contributor
              , 'query'              AS source
              , date('2023-03-03')   AS created_at
              , NOW()                AS updated_at
              , 'contract_deployers' AS model_name
              , 'persona'            AS label_type
FROM {{ source('optimism', 'creation_traces') }} creation
LEFT ANTI JOIN {{ source('optimism', 'creation_traces') }} anti_table 
ON creation.from = anti_table.address