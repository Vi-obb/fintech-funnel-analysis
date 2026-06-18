WITH user_level_events AS (
    SELECT
        u.user_id,
        u.signup_date,
        u.acquisition_channel,
        u.device_type,
        u.incentive_offered,

        MIN(CASE
            WHEN e.event_name = 'first_deposit'
            THEN e.event_timestamp
        END) AS first_deposit_timestamp,

        MIN(CASE
            WHEN e.event_name = 'first_transaction'
            THEN e.event_timestamp
        END) AS first_transaction_timestamp,

        SUM(CASE
            WHEN e.event_name = 'first_deposit'
            THEN e.amount
            ELSE 0
        END) AS deposit_volume,

        SUM(CASE
            WHEN e.event_name IN ('first_transaction', 'repeat_transaction')
            THEN e.amount
            ELSE 0
        END) AS transaction_volume

    FROM users u
    LEFT JOIN events e
        ON u.user_id = e.user_id
    GROUP BY
        u.user_id,
        u.signup_date,
        u.acquisition_channel,
        u.device_type,
        u.incentive_offered
),

user_level_metrics AS (
    SELECT
        user_id,
        signup_date,
        acquisition_channel,
        device_type,
        incentive_offered,

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

        deposit_volume,
        transaction_volume

    FROM user_level_events
),

channel_metrics AS (
    SELECT
        ulm.acquisition_channel,

        COUNT(*) AS users_count,

        SUM(ulm.made_deposit) AS deposit_users,
        SUM(ulm.made_transaction) AS transaction_users,
        SUM(ulm.activated_14d) AS activated_14d_users,

        ROUND(100.0 * SUM(ulm.made_deposit) / COUNT(*), 2) AS deposit_rate_pct,
        ROUND(100.0 * SUM(ulm.made_transaction) / COUNT(*), 2) AS transaction_rate_pct,
        ROUND(100.0 * SUM(ulm.activated_14d) / COUNT(*), 2) AS activation_14d_rate_pct,

        ROUND(SUM(ulm.deposit_volume), 2) AS total_deposit_volume,
        ROUND(SUM(ulm.transaction_volume), 2) AS total_transaction_volume,

        ROUND(
            SUM(ulm.deposit_volume) / NULLIF(SUM(ulm.made_deposit), 0),
            2
        ) AS avg_deposit_amount_per_depositor,

        ROUND(
            SUM(ulm.transaction_volume) / NULLIF(SUM(ulm.made_transaction), 0),
            2
        ) AS avg_transaction_volume_per_transacting_user,

        ROUND(COALESCE(SUM(i.estimated_revenue_30d), 0), 2) AS estimated_revenue_30d,
        ROUND(COALESCE(SUM(i.incentive_cost), 0), 2) AS incentive_cost,

        ROUND(
            COALESCE(SUM(i.estimated_revenue_30d), 0)
            - COALESCE(SUM(i.incentive_cost), 0),
            2
        ) AS net_profit_30d,

        ROUND(
            (
                COALESCE(SUM(i.estimated_revenue_30d), 0)
                - COALESCE(SUM(i.incentive_cost), 0)
            ) / COUNT(*),
            2
        ) AS net_profit_per_user

    FROM user_level_metrics ulm
    LEFT JOIN incentives i
        ON ulm.user_id = i.user_id
    GROUP BY ulm.acquisition_channel
)

SELECT
    acquisition_channel,
    users_count,
    deposit_users,
    transaction_users,
    activated_14d_users,
    deposit_rate_pct,
    transaction_rate_pct,
    activation_14d_rate_pct,
    total_deposit_volume,
    total_transaction_volume,
    avg_deposit_amount_per_depositor,
    avg_transaction_volume_per_transacting_user,
    estimated_revenue_30d,
    incentive_cost,
    net_profit_30d,
    net_profit_per_user

FROM channel_metrics
ORDER BY activation_14d_rate_pct DESC;