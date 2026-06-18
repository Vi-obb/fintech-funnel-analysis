DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS events;
DROP TABLE IF EXISTS incentives;

CREATE TABLE users (
    user_id INTEGER PRIMARY KEY,
    signup_date TEXT NOT NULL,
    country TEXT NOT NULL,
    age_band TEXT NOT NULL,
    acquisition_channel TEXT NOT NULL,
    device_type TEXT NOT NULL,
    risk_score REAL NOT NULL,
    kyc_required INTEGER NOT NULL,
    referred INTEGER NOT NULL,
    incentive_offered INTEGER NOT NULL
);

CREATE TABLE events (
    event_id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    event_timestamp TEXT NOT NULL,
    event_name TEXT NOT NULL,
    amount REAL,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE incentives (
    user_id INTEGER PRIMARY KEY,
    incentive_type TEXT NOT NULL,
    incentive_cost REAL NOT NULL,
    estimated_revenue_30d REAL NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE INDEX idx_events_user_id ON events(user_id);
CREATE INDEX idx_events_event_name ON events(event_name);
CREATE INDEX idx_events_timestamp ON events(event_timestamp);
CREATE INDEX idx_users_channel ON users(acquisition_channel);
CREATE INDEX idx_users_signup_date ON users(signup_date);