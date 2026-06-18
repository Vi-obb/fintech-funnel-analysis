WITH first_user_events AS (
    SELECT
        u.user_id,
        u.signup_date,
        u.acquisition_channel,
        u.device_type,
        u.incentive_offered,
        u.risk_score,

        MIN(CASE 
            WHEN e.event_name = 'first_deposit' 
            THEN e.event_timestamp 
        END) AS first_deposit_timestamp,

        MIN(CASE 
            WHEN e.event_name = 'first_transaction' 
            THEN e.event_timestamp 
        END) AS first_transaction_timestamp

    FROM users u
    LEFT JOIN events e
        ON u.user_id = e.user_id
    GROUP BY
        u.user_id,
        u.signup_date,
        u.acquisition_channel,
        u.device_type,
        u.incentive_offered,
        u.risk_score
),

activation_flags AS (
    SELECT
        user_id,
        signup_date,
        acquisition_channel,
        device_type,
        incentive_offered,
        risk_score,
        first_deposit_timestamp,
        first_transaction_timestamp,

        CASE
            WHEN first_deposit_timestamp IS NOT NULL THEN 1
            ELSE 0
        END AS made_deposit,

        CASE
            WHEN first_transaction_timestamp IS NOT NULL THEN 1
            ELSE 0
        END AS made_transaction,

        CASE
            WHEN first_transaction_timestamp IS NOT NULL
             AND julianday(first_transaction_timestamp) - julianday(signup_date) <= 14
            THEN 1
            ELSE 0
        END AS activated_14d,

        CASE
            WHEN first_transaction_timestamp IS NOT NULL
            THEN ROUND(julianday(first_transaction_timestamp) - julianday(signup_date), 2)
            ELSE NULL
        END AS days_to_first_transaction

    FROM first_user_events
),

overall_activation AS (
    SELECT
        'overall' AS segment_type,
        'all_users' AS segment_value,
        COUNT(*) AS users_count,
        SUM(made_deposit) AS deposit_users,
        SUM(made_transaction) AS transaction_users,
        SUM(activated_14d) AS activated_14d_users,

        ROUND(100.0 * SUM(made_deposit) / COUNT(*), 2) AS deposit_rate_pct,
        ROUND(100.0 * SUM(made_transaction) / COUNT(*), 2) AS transaction_rate_pct,
        ROUND(100.0 * SUM(activated_14d) / COUNT(*), 2) AS activation_14d_rate_pct,

        ROUND(AVG(days_to_first_transaction), 2) AS avg_days_to_first_transaction

    FROM activation_flags
),

activation_by_channel AS (
    SELECT
        'acquisition_channel' AS segment_type,
        acquisition_channel AS segment_value,
        COUNT(*) AS users_count,
        SUM(made_deposit) AS deposit_users,
        SUM(made_transaction) AS transaction_users,
        SUM(activated_14d) AS activated_14d_users,

        ROUND(100.0 * SUM(made_deposit) / COUNT(*), 2) AS deposit_rate_pct,
        ROUND(100.0 * SUM(made_transaction) / COUNT(*), 2) AS transaction_rate_pct,
        ROUND(100.0 * SUM(activated_14d) / COUNT(*), 2) AS activation_14d_rate_pct,

        ROUND(AVG(days_to_first_transaction), 2) AS avg_days_to_first_transaction

    FROM activation_flags
    GROUP BY acquisition_channel
),

activation_by_device AS (
    SELECT
        'device_type' AS segment_type,
        device_type AS segment_value,
        COUNT(*) AS users_count,
        SUM(made_deposit) AS deposit_users,
        SUM(made_transaction) AS transaction_users,
        SUM(activated_14d) AS activated_14d_users,

        ROUND(100.0 * SUM(made_deposit) / COUNT(*), 2) AS deposit_rate_pct,
        ROUND(100.0 * SUM(made_transaction) / COUNT(*), 2) AS transaction_rate_pct,
        ROUND(100.0 * SUM(activated_14d) / COUNT(*), 2) AS activation_14d_rate_pct,

        ROUND(AVG(days_to_first_transaction), 2) AS avg_days_to_first_transaction

    FROM activation_flags
    GROUP BY device_type
),

activation_by_incentive AS (
    SELECT
        'incentive_offered' AS segment_type,
        CASE
            WHEN incentive_offered = 1 THEN 'incentivized'
            ELSE 'not_incentivized'
        END AS segment_value,
        COUNT(*) AS users_count,
        SUM(made_deposit) AS deposit_users,
        SUM(made_transaction) AS transaction_users,
        SUM(activated_14d) AS activated_14d_users,

        ROUND(100.0 * SUM(made_deposit) / COUNT(*), 2) AS deposit_rate_pct,
        ROUND(100.0 * SUM(made_transaction) / COUNT(*), 2) AS transaction_rate_pct,
        ROUND(100.0 * SUM(activated_14d) / COUNT(*), 2) AS activation_14d_rate_pct,

        ROUND(AVG(days_to_first_transaction), 2) AS avg_days_to_first_transaction

    FROM activation_flags
    GROUP BY incentive_offered
)

SELECT *
FROM overall_activation

UNION ALL

SELECT *
FROM activation_by_channel

UNION ALL

SELECT *
FROM activation_by_device

UNION ALL

SELECT *
FROM activation_by_incentive

ORDER BY
    segment_type,
    activation_14d_rate_pct DESC;