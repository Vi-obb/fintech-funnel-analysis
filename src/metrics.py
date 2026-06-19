from pathlib import Path

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
PROCESSED_DATA_DIR = PROJECT_ROOT / "data" / "processed"


def load_processed_csv(filename: str) -> pd.DataFrame:
    """
    Load a processed CSV file from data/processed.

    Parameters
    ----------
    filename:
        Name of the CSV file, for example 'funnel_analysis.csv'.

    Returns
    -------
    pandas.DataFrame
        Loaded CSV as a DataFrame.
    """
    file_path = PROCESSED_DATA_DIR / filename

    if not file_path.exists():
        raise FileNotFoundError(
            f"Could not find {file_path}. "
            "Make sure you have generated the processed SQL outputs."
        )

    return pd.read_csv(file_path)


def calculate_percentage_point_gap(
    df: pd.DataFrame,
    group_column: str,
    metric_column: str,
    high_group: str,
    low_group: str,
) -> float:
    """
    Calculate the percentage-point gap between two groups.

    Example:
    referral activation rate - paid_social activation rate.
    """
    high_value = df.loc[df[group_column] == high_group, metric_column].iloc[0]
    low_value = df.loc[df[group_column] == low_group, metric_column].iloc[0]

    return round(high_value - low_value, 2)


def get_top_row(df: pd.DataFrame, metric_column: str) -> pd.Series:
    """
    Return the row with the highest value for a given metric.
    """
    return df.sort_values(metric_column, ascending=False).iloc[0]


def get_bottom_row(df: pd.DataFrame, metric_column: str) -> pd.Series:
    """
    Return the row with the lowest value for a given metric.
    """
    return df.sort_values(metric_column, ascending=True).iloc[0]
