# Executive Summary: Fintech Product Funnel & Activation Analysis

## Objective

This project analyzes a synthetic fintech app dataset to understand how users move from signup to activation, which acquisition channels bring the highest-quality users, whether incentives are profitable, and how user retention behaves after signup.

The analysis focuses on a consumer fintech onboarding journey:

```text
Signup → Verification → KYC Submission → KYC Approval → First Deposit → First Transaction
```

A user is defined as activated if they complete a first transaction within 14 days of signup.

---

## Key Metrics

| Metric | Result |
|---|---:|
| Signed-up users | 10,000 |
| Verified users | 8,509 |
| KYC submitted users | 6,108 |
| KYC approved users | 5,041 |
| First deposit users | 3,696 |
| First transaction users | 2,920 |
| Signup-to-first-transaction conversion | 29.2% |
| 14-day activated users | 2,870 |
| 14-day activation rate | 28.7% |

---

## Main Findings

### 1. KYC submission is the largest onboarding bottleneck

The largest funnel drop-off occurs between verification completion and KYC submission.

| Funnel Step | Users |
|---|---:|
| Verification completed | 8,509 |
| KYC submitted | 6,108 |
| Drop-off | 2,401 |
| Drop-off rate | 28.22% |

This suggests that users are willing to begin onboarding, but many do not continue into the identity verification process. The likely business issue is KYC friction, unclear document requirements, low trust, or weak onboarding prompts.

---

### 2. First deposit conversion is the second major friction point

After KYC approval, 5,041 users are eligible to continue, but only 3,696 users make a first deposit.

| Funnel Step | Users |
|---|---:|
| KYC approved | 5,041 |
| First deposit | 3,696 |
| Drop-off | 1,345 |
| Drop-off rate | 26.68% |

This suggests that funding the account is another major conversion barrier. Possible causes include weak funding calls-to-action, limited payment methods, deposit fees, lack of trust, or unclear product value.

---

### 3. Referral and paid search produce the strongest activation

Activation varies significantly by acquisition channel.

| Channel | 14-Day Activation Rate |
|---|---:|
| Referral | 41.12% |
| Paid search | 34.75% |
| Organic | 28.82% |
| Affiliate | 18.64% |
| Paid social | 18.10% |

Referral users activate 23.02 percentage points higher than paid social users.

This suggests that referral and paid search bring higher-intent users, while paid social appears to generate weaker user quality.

---

### 4. Incentives improve activation but do not recover cost within 30 days

Incentivized users activate more than non-incentivized users.

| Segment | 14-Day Activation Rate |
|---|---:|
| Incentivized users | 32.89% |
| Non-incentivized users | 25.14% |
| Activation gap | 7.75 percentage points |

However, estimated 30-day revenue does not recover incentive cost.

| Incentive Metric | Result |
|---|---:|
| Total incentive cost | 41,280.00 |
| Estimated 30-day revenue | 3,637.41 |
| Net profit | -37,642.59 |
| Revenue-to-cost ratio | 0.088 |

This suggests that incentives are effective for activation but inefficient under the current payout and revenue assumptions.

---

### 5. Cashback is the most efficient incentive type

Referral bonuses produce the highest activation, but cashback is more efficient on cost per activated user.

| Incentive Type | Activation Rate | Cost per Activated User |
|---|---:|---:|
| Referral bonus | 41.64% | 28.82 |
| Cashback | 40.18% | 12.44 |
| Welcome bonus | 22.58% | 35.43 |
| Affiliate reward | 24.34% | 41.09 |

Cashback produces nearly the same activation rate as referral bonuses at a much lower cost per activated user.

This makes cashback the strongest candidate for further controlled experiments.

---

### 6. Retention weakens after early transaction activity

Retention peaks around week 1 and then stabilizes at a lower level from weeks 2 to 4.

This pattern reflects the synthetic product journey, where users often need several days to complete verification, KYC, deposit, and first transaction.

The business concern is that many users reach initial transaction activity but do not yet form a durable transaction habit.

---

## Recommendations

### 1. Reduce KYC submission friction

The largest leak happens before KYC submission. The product team should test:

- clearer KYC instructions,
- document upload guidance,
- progress indicators,
- reminder flows,
- trust-building copy around identity verification.

### 2. Improve first deposit conversion

A large share of KYC-approved users still do not fund their account. The team should test:

- stronger post-approval deposit prompts,
- clearer funding calls-to-action,
- more local payment methods,
- deposit safety messaging,
- onboarding screens that explain why funding is necessary.

### 3. Reallocate spend away from weak paid social acquisition

Paid social has low activation and weak short-term profitability. It should not be scaled blindly.

Recommended action:

- narrow paid social targeting,
- test new creatives,
- compare paid social cohorts by audience,
- reduce spend if activation does not improve.

### 4. Scale referral carefully

Referral brings high-activation users, but referral bonuses are expensive.

Recommended action:

- test lower referral payouts,
- introduce delayed rewards after first transaction,
- require minimum transaction volume before reward payout,
- compare referral payback by user segment.

### 5. Prioritize cashback-style experiments

Cashback appears to be the most efficient incentive type.

Recommended action:

- run controlled cashback experiments,
- compare cashback against referral bonuses,
- optimize cashback value by user segment,
- measure payback beyond 30 days.

### 6. Improve post-transaction lifecycle engagement

Retention weakens after initial transaction activity.

Recommended action:

- build repeat-transaction reminders,
- introduce habit-forming lifecycle messages,
- educate users on additional use cases,
- test reactivation campaigns for users who transact once and become inactive.

---

## Limitations

This analysis uses synthetic data, so findings should be interpreted as a demonstration of workflow rather than evidence about a real fintech product.

Key limitations:

1. Relationships between channels, incentives, and activation are simulated.
2. Estimated revenue is simplified.
3. Acquisition cost is not modelled separately from incentive cost.
4. The analysis does not include fraud losses, chargebacks, subscriptions, FX spread, interchange, servicing cost, or cost of capital.
5. Incentive results are descriptive and should not be interpreted causally.
6. Retention only considers transaction events, not broader engagement.

---

## Conclusion

The synthetic fintech product shows meaningful early user interest but loses users at critical points in the journey.

The biggest operational issue is KYC submission friction. The biggest commercial issue is that incentives improve activation but do not generate enough estimated 30-day revenue to recover subsidy cost.

The highest-leverage next steps are to reduce KYC friction, improve first deposit conversion, retarget weak paid social acquisition, redesign referral incentives around payback, and test lower-cost cashback incentives.
