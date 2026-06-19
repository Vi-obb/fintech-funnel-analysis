WITH first_transactions AS (
    SELECT
        user_id,
        MIN(event_timestamp) AS first_transaction_timestamp
    FROM events
    WHERE event_name = 'first_transaction'
    GROUP BY user_id
),

activation_flags AS (
    SELECT
        u.user_id,
        u.signup_date,
        u.acquisition_channel,
        u.incentive_offered,
        i.incentive_type,
        i.incentive_cost,
        i.estimated_revenue_30d,

        CASE
            WHEN ft.first_transaction_timestamp IS NOT NULL
             AND julianday(ft.first_transaction_timestamp) - julianday(u.signup_date) <= 14
            THEN 1
            ELSE 0
        END AS activated_14d

    FROM users u
    INNER JOIN incentives i
        ON u.user_id = i.user_id
    LEFT JOIN first_transactions ft
        ON u.user_id = ft.user_id
),

incentive_type_metrics AS (
    SELECT
        incentive_type,
        COUNT(*) AS incentivized_users,
        SUM(activated_14d) AS activated_14d_users,

        ROUND(
            100.0 * SUM(activated_14d) / COUNT(*),
            2
        ) AS activation_14d_rate_pct,

        ROUND(SUM(incentive_cost), 2) AS total_incentive_cost,
        ROUND(SUM(estimated_revenue_30d), 2) AS estimated_revenue_30d,

        ROUND(
            SUM(estimated_revenue_30d) - SUM(incentive_cost),
            2
        ) AS net_profit_30d,

        ROUND(
            (SUM(estimated_revenue_30d) - SUM(incentive_cost)) / COUNT(*),
            2
        ) AS net_profit_per_incentivized_user,

        ROUND(
            SUM(estimated_revenue_30d) / NULLIF(SUM(incentive_cost), 0),
            3
        ) AS revenue_to_cost_ratio,

        ROUND(
            SUM(incentive_cost) / NULLIF(SUM(activated_14d), 0),
            2
        ) AS incentive_cost_per_activated_user

    FROM activation_flags
    GROUP BY incentive_type
),

overall_incentive_metrics AS (
    SELECT
        'all_incentives' AS incentive_type,
        COUNT(*) AS incentivized_users,
        SUM(activated_14d) AS activated_14d_users,

        ROUND(
            100.0 * SUM(activated_14d) / COUNT(*),
            2
        ) AS activation_14d_rate_pct,

        ROUND(SUM(incentive_cost), 2) AS total_incentive_cost,
        ROUND(SUM(estimated_revenue_30d), 2) AS estimated_revenue_30d,

        ROUND(
            SUM(estimated_revenue_30d) - SUM(incentive_cost),
            2
        ) AS net_profit_30d,

        ROUND(
            (SUM(estimated_revenue_30d) - SUM(incentive_cost)) / COUNT(*),
            2
        ) AS net_profit_per_incentivized_user,

        ROUND(
            SUM(estimated_revenue_30d) / NULLIF(SUM(incentive_cost), 0),
            3
        ) AS revenue_to_cost_ratio,

        ROUND(
            SUM(incentive_cost) / NULLIF(SUM(activated_14d), 0),
            2
        ) AS incentive_cost_per_activated_user

    FROM activation_flags
),

combined_metrics AS (
    SELECT *
    FROM overall_incentive_metrics

    UNION ALL

    SELECT *
    FROM incentive_type_metrics
)

SELECT
    incentive_type,
    incentivized_users,
    activated_14d_users,
    activation_14d_rate_pct,
    total_incentive_cost,
    estimated_revenue_30d,
    net_profit_30d,
    net_profit_per_incentivized_user,
    revenue_to_cost_ratio,
    incentive_cost_per_activated_user
FROM combined_metrics
ORDER BY
    CASE
        WHEN incentive_type = 'all_incentives' THEN 0
        ELSE 1
    END,
    net_profit_per_incentivized_user DESC;