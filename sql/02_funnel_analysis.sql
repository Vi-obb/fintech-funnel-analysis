WITH user_funnel_flags AS (
    SELECT
        u.user_id,

        MAX(CASE WHEN e.event_name = 'signup' THEN 1 ELSE 0 END) AS signed_up,
        MAX(CASE WHEN e.event_name = 'verification_completed' THEN 1 ELSE 0 END) AS verified,
        MAX(CASE WHEN e.event_name = 'kyc_submitted' THEN 1 ELSE 0 END) AS kyc_submitted,
        MAX(CASE WHEN e.event_name = 'kyc_approved' THEN 1 ELSE 0 END) AS kyc_approved,
        MAX(CASE WHEN e.event_name = 'first_deposit' THEN 1 ELSE 0 END) AS first_deposit,
        MAX(CASE WHEN e.event_name = 'first_transaction' THEN 1 ELSE 0 END) AS first_transaction

    FROM users u
    LEFT JOIN events e
        ON u.user_id = e.user_id
    GROUP BY u.user_id
),

funnel_counts AS (
    SELECT
        1 AS step_order,
        'Signup' AS funnel_step,
        SUM(signed_up) AS users_count
    FROM user_funnel_flags

    UNION ALL

    SELECT
        2 AS step_order,
        'Verification Completed' AS funnel_step,
        SUM(verified) AS users_count
    FROM user_funnel_flags

    UNION ALL

    SELECT
        3 AS step_order,
        'KYC Submitted' AS funnel_step,
        SUM(kyc_submitted) AS users_count
    FROM user_funnel_flags

    UNION ALL

    SELECT
        4 AS step_order,
        'KYC Approved' AS funnel_step,
        SUM(kyc_approved) AS users_count
    FROM user_funnel_flags

    UNION ALL

    SELECT
        5 AS step_order,
        'First Deposit' AS funnel_step,
        SUM(first_deposit) AS users_count
    FROM user_funnel_flags

    UNION ALL

    SELECT
        6 AS step_order,
        'First Transaction' AS funnel_step,
        SUM(first_transaction) AS users_count
    FROM user_funnel_flags
),

funnel_with_previous_step AS (
    SELECT
        step_order,
        funnel_step,
        users_count,
        LAG(users_count) OVER (ORDER BY step_order) AS previous_step_users,
        FIRST_VALUE(users_count) OVER (ORDER BY step_order) AS signup_users
    FROM funnel_counts
)

SELECT
    step_order,
    funnel_step,
    users_count,

    ROUND(
        100.0 * users_count / previous_step_users,
        2
    ) AS conversion_from_previous_step_pct,

    ROUND(
        100.0 * users_count / signup_users,
        2
    ) AS conversion_from_signup_pct,

    CASE
        WHEN previous_step_users IS NULL THEN NULL
        ELSE previous_step_users - users_count
    END AS dropoff_users,

    CASE
        WHEN previous_step_users IS NULL THEN NULL
        ELSE ROUND(100.0 * (previous_step_users - users_count) / previous_step_users, 2)
    END AS dropoff_from_previous_step_pct

FROM funnel_with_previous_step
ORDER BY step_order;