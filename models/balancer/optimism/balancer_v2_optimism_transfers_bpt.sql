{{
    config(
        schema = 'balancer_v2_optimism',
        alias = alias('transfers_bpt'),
        partition_by = ['block_date'],
        materialized = 'incremental',
        file_format = 'delta',
        incremental_strategy = 'merge',
        unique_key = ['block_date', 'evt_tx_hash', 'evt_index'],
        post_hook='{{ expose_spells(\'["optimism"]\',
                                    "project",
                                    "balancer_v2",
                                    \'["stefenon"]\') }}'
    )
}}

{% set event_signature = '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef' %}
{% set project_start_date = '2022-05-19' %}

WITH registered_pools AS (
    SELECT
      DISTINCT poolAddress AS pool_address
    FROM
      {{ source('balancer_v2_optimism', 'Vault_evt_PoolRegistered') }}
    {% if is_incremental() %}
    WHERE evt_block_time >= DATE_TRUNC('day', NOW() - interval '1 week')
    {% endif %} 
  )

SELECT DISTINCT * FROM (
    SELECT
        logs.contract_address,
        logs.tx_hash AS evt_tx_hash,
        logs.index AS evt_index,
        logs.block_time AS evt_block_time,
        TRY_CAST(date_trunc('DAY', logs.block_time) AS date) AS block_date,
        logs.block_number AS evt_block_number,
        CONCAT('0x', SUBSTRING(logs.topic2, 27, 40)) AS from,
        CONCAT('0x', SUBSTRING(logs.topic3, 27, 40)) AS to,
        bytea2numeric(SUBSTRING(logs.data, 32, 64)) AS value
    FROM {{ source('optimism', 'logs') }} logs
    INNER JOIN registered_pools p ON p.pool_address = logs.contract_address
    WHERE logs.topic1 = '{{ event_signature }}'
        {% if not is_incremental() %}
        AND logs.block_time >= '{{ project_start_date }}'
        {% endif %}
        {% if is_incremental() %}
        AND logs.block_time >= DATE_TRUNC('day', NOW() - interval '1 week')
        {% endif %} ) transfers
