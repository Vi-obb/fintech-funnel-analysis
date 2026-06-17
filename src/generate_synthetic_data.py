from pathlib import Path
import numpy as np
import pandas as pd


RANDOM_SEED = 42
N_USERS = 10_000

PROJECT_ROOT = Path(__file__).resolve().parents[1]
RAW_DATA_DIR = PROJECT_ROOT / "data" / "raw"


def choose_with_probs(rng, values, probs, size):
    """
    Helper function for drawing categorical values with fixed probabilities.
    """
    return rng.choice(values, size=size, p=probs)


def generate_users(rng):
    """
    Generate one row per user.

    This table represents relatively stable user attributes known at or near signup.
    """
    user_ids = np.arange(1, N_USERS + 1)

    signup_dates = pd.to_datetime(
        rng.choice(
            pd.date_range("2025-01-01", "2025-03-31", freq="D"),
            size=N_USERS,
            replace=True,
        )
    )

    countries = choose_with_probs(
        rng,
        values=["UK", "Germany", "France", "Spain", "Ghana", "Nigeria"],
        probs=[0.30, 0.20, 0.15, 0.15, 0.10, 0.10],
        size=N_USERS,
    )

    age_bands = choose_with_probs(
        rng,
        values=["18-24", "25-34", "35-44", "45-54", "55+"],
        probs=[0.25, 0.38, 0.22, 0.10, 0.05],
        size=N_USERS,
    )

    acquisition_channels = choose_with_probs(
        rng,
        values=["organic", "paid_search", "paid_social", "referral", "affiliate"],
        probs=[0.28, 0.22, 0.25, 0.17, 0.08],
        size=N_USERS,
    )

    device_types = choose_with_probs(
        rng,
        values=["iOS", "Android", "Web"],
        probs=[0.45, 0.45, 0.10],
        size=N_USERS,
    )

    # Risk score is synthetic. Higher values represent users more likely to hit friction in KYC.
    risk_score = np.clip(rng.normal(loc=0.45, scale=0.18, size=N_USERS), 0, 1)

    referred = acquisition_channels == "referral"

    # Incentives are more common for referral and paid channels.
    incentive_probability = np.select(
        [
            acquisition_channels == "referral",
            acquisition_channels == "paid_social",
            acquisition_channels == "paid_search",
            acquisition_channels == "affiliate",
            acquisition_channels == "organic",
        ],
        [0.95, 0.55, 0.40, 0.50, 0.10],
        default=0.20,
    )

    incentive_offered = rng.random(N_USERS) < incentive_probability

    # In this synthetic fintech, most users require KYC.
    kyc_required = rng.random(N_USERS) < 0.92

    users = pd.DataFrame(
        {
            "user_id": user_ids,
            "signup_date": signup_dates,
            "country": countries,
            "age_band": age_bands,
            "acquisition_channel": acquisition_channels,
            "device_type": device_types,
            "risk_score": risk_score.round(3),
            "kyc_required": kyc_required,
            "referred": referred,
            "incentive_offered": incentive_offered,
        }
    )

    return users


def channel_quality_adjustment(channel):
    """
    Business logic: different acquisition channels bring different user quality.

    Positive values improve conversion probabilities.
    Negative values reduce conversion probabilities.
    """
    adjustments = {
        "organic": 0.04,
        "paid_search": 0.06,
        "paid_social": -0.06,
        "referral": 0.08,
        "affiliate": -0.02,
    }
    return adjustments[channel]


def device_adjustment(device):
    """
    Synthetic assumption: app users convert better than web users.
    """
    adjustments = {
        "iOS": 0.03,
        "Android": 0.01,
        "Web": -0.05,
    }
    return adjustments[device]


def sigmoid(x):
    """
    Convert a score into a probability between 0 and 1.
    """
    return 1 / (1 + np.exp(-x))


def generate_events(users, rng):
    """
    Generate event-level data.

    Each user starts with signup. Later events occur probabilistically based on
    user attributes, acquisition quality, device type, risk score, and incentives.
    """
    events = []
    event_id = 1

    for row in users.itertuples(index=False):
        user_id = row.user_id
        signup_ts = pd.Timestamp(row.signup_date) + pd.Timedelta(
            hours=int(rng.integers(0, 24)),
            minutes=int(rng.integers(0, 60)),
        )

        events.append(
            {
                "event_id": event_id,
                "user_id": user_id,
                "event_timestamp": signup_ts,
                "event_name": "signup",
                "amount": np.nan,
            }
        )
        event_id += 1

        quality = channel_quality_adjustment(row.acquisition_channel)
        device = device_adjustment(row.device_type)
        incentive_boost = 0.04 if row.incentive_offered else 0.00
        risk_penalty = 0.18 * row.risk_score

        # Step 1: verification
        p_verify = np.clip(0.82 + quality + device + incentive_boost - 0.05 * row.risk_score, 0.05, 0.98)
        verified = rng.random() < p_verify

        if not verified:
            continue

        verification_ts = signup_ts + pd.Timedelta(hours=int(rng.integers(1, 36)))
        events.append(
            {
                "event_id": event_id,
                "user_id": user_id,
                "event_timestamp": verification_ts,
                "event_name": "verification_completed",
                "amount": np.nan,
            }
        )
        event_id += 1

        # Step 2: KYC submitted
        if row.kyc_required:
            p_kyc_submit = np.clip(0.76 + quality + device + incentive_boost - 0.08 * row.risk_score, 0.05, 0.98)
            kyc_submitted = rng.random() < p_kyc_submit

            if not kyc_submitted:
                continue

            kyc_submit_ts = verification_ts + pd.Timedelta(hours=int(rng.integers(1, 72)))
            events.append(
                {
                    "event_id": event_id,
                    "user_id": user_id,
                    "event_timestamp": kyc_submit_ts,
                    "event_name": "kyc_submitted",
                    "amount": np.nan,
                }
            )
            event_id += 1

            # Step 3: KYC approved
            p_kyc_approved = np.clip(0.88 + quality - risk_penalty, 0.05, 0.98)
            kyc_approved = rng.random() < p_kyc_approved

            if not kyc_approved:
                continue

            kyc_approved_ts = kyc_submit_ts + pd.Timedelta(hours=int(rng.integers(2, 96)))
            events.append(
                {
                    "event_id": event_id,
                    "user_id": user_id,
                    "event_timestamp": kyc_approved_ts,
                    "event_name": "kyc_approved",
                    "amount": np.nan,
                }
            )
            event_id += 1
        else:
            kyc_approved_ts = verification_ts

        # Step 4: first deposit
        p_deposit = np.clip(0.58 + quality + device + 0.07 * row.incentive_offered - 0.05 * row.risk_score, 0.05, 0.95)
        deposited = rng.random() < p_deposit

        if not deposited:
            continue

        deposit_ts = kyc_approved_ts + pd.Timedelta(hours=int(rng.integers(1, 120)))
        deposit_amount = float(np.round(rng.lognormal(mean=3.4, sigma=0.75), 2))

        events.append(
            {
                "event_id": event_id,
                "user_id": user_id,
                "event_timestamp": deposit_ts,
                "event_name": "first_deposit",
                "amount": deposit_amount,
            }
        )
        event_id += 1

        # Step 5: first transaction
        p_transaction = np.clip(0.72 + quality + device + 0.04 * row.incentive_offered, 0.05, 0.98)
        transacted = rng.random() < p_transaction

        if not transacted:
            continue

        transaction_ts = deposit_ts + pd.Timedelta(hours=int(rng.integers(1, 96)))
        transaction_amount = float(np.round(rng.lognormal(mean=3.0, sigma=0.7), 2))

        events.append(
            {
                "event_id": event_id,
                "user_id": user_id,
                "event_timestamp": transaction_ts,
                "event_name": "first_transaction",
                "amount": transaction_amount,
            }
        )
        event_id += 1

        # Step 6: repeat transactions for retention analysis
        expected_repeat_txns = {
            "organic": 2.2,
            "paid_search": 2.0,
            "paid_social": 1.2,
            "referral": 2.5,
            "affiliate": 1.5,
        }[row.acquisition_channel]

        n_repeat_txns = rng.poisson(expected_repeat_txns)

        for _ in range(n_repeat_txns):
            repeat_ts = transaction_ts + pd.Timedelta(days=int(rng.integers(1, 35)))
            repeat_amount = float(np.round(rng.lognormal(mean=2.8, sigma=0.8), 2))

            events.append(
                {
                    "event_id": event_id,
                    "user_id": user_id,
                    "event_timestamp": repeat_ts,
                    "event_name": "repeat_transaction",
                    "amount": repeat_amount,
                }
            )
            event_id += 1

    events_df = pd.DataFrame(events)
    events_df = events_df.sort_values(["user_id", "event_timestamp"]).reset_index(drop=True)

    return events_df


def generate_incentives(users, events, rng):
    """
    Generate incentive cost and estimated 30-day revenue.

    This table supports incentive profitability analysis.
    """
    incentive_users = users[users["incentive_offered"]].copy()

    incentive_type = np.select(
        [
            incentive_users["acquisition_channel"] == "referral",
            incentive_users["acquisition_channel"] == "paid_social",
            incentive_users["acquisition_channel"] == "paid_search",
            incentive_users["acquisition_channel"] == "affiliate",
            incentive_users["acquisition_channel"] == "organic",
        ],
        [
            "referral_bonus",
            "welcome_bonus",
            "cashback",
            "affiliate_reward",
            "welcome_bonus",
        ],
        default="welcome_bonus",
    )

    incentive_users["incentive_type"] = incentive_type

    cost_map = {
        "referral_bonus": 12.00,
        "welcome_bonus": 8.00,
        "cashback": 5.00,
        "affiliate_reward": 10.00,
    }

    incentive_users["incentive_cost"] = incentive_users["incentive_type"].map(cost_map)

    transaction_events = events[
        events["event_name"].isin(["first_transaction", "repeat_transaction"])
    ].copy()

    transaction_revenue = (
        transaction_events.groupby("user_id")["amount"]
        .sum()
        .reset_index(name="transaction_volume_30d")
    )

    incentives = incentive_users[
        ["user_id", "incentive_type", "incentive_cost"]
    ].merge(transaction_revenue, on="user_id", how="left")

    incentives["transaction_volume_30d"] = incentives["transaction_volume_30d"].fillna(0)

    # Simple synthetic revenue model:
    # assume the fintech earns 1.2% of transaction volume plus small noise.
    incentives["estimated_revenue_30d"] = (
        incentives["transaction_volume_30d"] * 0.012
        + rng.normal(loc=0.50, scale=0.25, size=len(incentives))
    )

    incentives["estimated_revenue_30d"] = incentives["estimated_revenue_30d"].clip(lower=0).round(2)
    incentives["incentive_cost"] = incentives["incentive_cost"].round(2)

    return incentives[
        ["user_id", "incentive_type", "incentive_cost", "estimated_revenue_30d"]
    ]


def main():
    RAW_DATA_DIR.mkdir(parents=True, exist_ok=True)

    rng = np.random.default_rng(RANDOM_SEED)

    users = generate_users(rng)
    events = generate_events(users, rng)
    incentives = generate_incentives(users, events, rng)

    users.to_csv(RAW_DATA_DIR / "users.csv", index=False)
    events.to_csv(RAW_DATA_DIR / "events.csv", index=False)
    incentives.to_csv(RAW_DATA_DIR / "incentives.csv", index=False)

    print("Synthetic data generated successfully.")
    print(f"Users: {len(users):,}")
    print(f"Events: {len(events):,}")
    print(f"Incentives: {len(incentives):,}")
    print(f"Files saved to: {RAW_DATA_DIR}")


if __name__ == "__main__":
    main()