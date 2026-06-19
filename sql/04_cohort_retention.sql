WITH user_cohorts AS (
    SELECT
        user_id,
        signup_date,

        -- Monday-based signup week approximation.
        date(
            signup_date,
            '-' || ((CAST(strftime('%w', signup_date) AS INTEGER) + 6) % 7) || ' days'
        ) AS signup_week
    FROM users
),

transaction_events AS (
    SELECT
        user_id,
        date(event_timestamp) AS transaction_date
    FROM events
    WHERE event_name IN ('first_transaction', 'repeat_transaction')
),

user_transaction_weeks AS (
    SELECT
        uc.user_id,
        uc.signup_week,
        CAST(
            (
                julianday(te.transaction_date) - julianday(uc.signup_week)
            ) / 7 AS INTEGER
        ) AS week_number
    FROM user_cohorts uc
    INNER JOIN transaction_events te
        ON uc.user_id = te.user_id
    WHERE
        CAST(
            (
                julianday(te.transaction_date) - julianday(uc.signup_week)
            ) / 7 AS INTEGER
        ) BETWEEN 0 AND 4
),

cohort_sizes AS (
    SELECT
        signup_week,
        COUNT(*) AS cohort_users
    FROM user_cohorts
    GROUP BY signup_week
),

retained_users AS (
    SELECT
        signup_week,
        week_number,
        COUNT(DISTINCT user_id) AS retained_users
    FROM user_transaction_weeks
    GROUP BY
        signup_week,
        week_number
),

retention_long AS (
    SELECT
        cs.signup_week,
        cs.cohort_users,
        weeks.week_number,
        COALESCE(ru.retained_users, 0) AS retained_users,
        ROUND(
            100.0 * COALESCE(ru.retained_users, 0) / cs.cohort_users,
            2
        ) AS retention_rate_pct
    FROM cohort_sizes cs
    CROSS JOIN (
        SELECT 0 AS week_number
        UNION ALL SELECT 1
        UNION ALL SELECT 2
        UNION ALL SELECT 3
        UNION ALL SELECT 4
    ) weeks
    LEFT JOIN retained_users ru
        ON cs.signup_week = ru.signup_week
       AND weeks.week_number = ru.week_number
)

SELECT
    signup_week,
    cohort_users,

    MAX(CASE WHEN week_number = 0 THEN retained_users END) AS week_0_users,
    MAX(CASE WHEN week_number = 0 THEN retention_rate_pct END) AS week_0_retention_pct,

    MAX(CASE WHEN week_number = 1 THEN retained_users END) AS week_1_users,
    MAX(CASE WHEN week_number = 1 THEN retention_rate_pct END) AS week_1_retention_pct,

    MAX(CASE WHEN week_number = 2 THEN retained_users END) AS week_2_users,
    MAX(CASE WHEN week_number = 2 THEN retention_rate_pct END) AS week_2_retention_pct,

    MAX(CASE WHEN week_number = 3 THEN retained_users END) AS week_3_users,
    MAX(CASE WHEN week_number = 3 THEN retention_rate_pct END) AS week_3_retention_pct,

    MAX(CASE WHEN week_number = 4 THEN retained_users END) AS week_4_users,
    MAX(CASE WHEN week_number = 4 THEN retention_rate_pct END) AS week_4_retention_pct

FROM retention_long
GROUP BY
    signup_week,
    cohort_users
ORDER BY signup_week;