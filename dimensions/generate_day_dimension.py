import csv
from datetime import date, timedelta

start_date = date(2026, 1, 1)
end_date = date(2031, 12, 31)

month_names = [
    "", "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
]

day_names = [
    "Monday", "Tuesday", "Wednesday", "Thursday",
    "Friday", "Saturday", "Sunday"
]

def get_season(month):
    if month in [12, 1, 2]:
        return (1, "Winter")
    elif month in [3, 4, 5]:
        return (2, "Spring")
    elif month in [6, 7, 8]:
        return (3, "Summer")
    else:
        return (4, "Fall")


with open("day.csv", "w", newline="") as f:
    writer = csv.writer(f)

    writer.writerow([
        "day_key",
        "full_date",
        "day_of_month",
        "day_of_year",
        "month_number",
        "month_name",
        "quarter_number",
        "quarter_name",
        "year_number",
        "day_of_week_number",
        "day_of_week_name",
        "is_weekend",
        "season_number",
        "season_name"
    ])

    current = start_date
    while current <= end_date:
        month = current.month
        quarter = (month - 1) // 3 + 1
        day_of_week_number = current.isoweekday()
        is_weekend = day_of_week_number >= 6
        day_of_year = current.timetuple().tm_yday

        season_number, season_name = get_season(month)

        writer.writerow([
            int(current.strftime("%Y%m%d")),
            current.isoformat(),
            current.day,
            day_of_year,
            month,
            month_names[month],
            quarter,
            f"Q{quarter}",
            current.year,
            day_of_week_number,
            day_names[day_of_week_number - 1],
            is_weekend,
            season_number,
            season_name
        ])

        current += timedelta(days=1)

print("day.csv generated successfully.")