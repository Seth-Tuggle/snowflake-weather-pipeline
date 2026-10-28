import csv

def get_day_period(hour):
    if 0 <= hour <= 4:
        return "Night"
    elif 5 <= hour <= 7:
        return "Early Morning"
    elif 8 <= hour <= 10:
        return "Morning"
    elif hour == 11:
        return "Late Morning"
    elif 12 <= hour <= 14:
        return "Early Afternoon"
    elif 15 <= hour <= 17:
        return "Late Afternoon"
    elif 18 <= hour <= 20:
        return "Evening"
    else:
        return "Late Evening"


with open("minute.csv", "w", newline="") as f:
    writer = csv.writer(f)

    writer.writerow([
        "minute_key",
        "hour_24",
        "hour_12",
        "minute_number",
        "time_24",
        "time_12",
        "am_pm",
        "day_period",
        "is_hour_start",
        "hour_label"
    ])

    for minute_key in range(1440):
        hour = minute_key // 60
        minute = minute_key % 60

        hour_12 = hour % 12
        if hour_12 == 0:
            hour_12 = 12

        am_pm = "AM" if hour < 12 else "PM"
        time_24 = f"{hour:02d}:{minute:02d}"
        time_12 = f"{hour_12}:{minute:02d} {am_pm}"
        day_period = get_day_period(hour)
        is_hour_start = (minute == 0)
        hour_label = f"{hour:02d}:00"

        writer.writerow([
            minute_key,
            hour,
            hour_12,
            minute,
            time_24,
            time_12,
            am_pm,
            day_period,
            is_hour_start,
            hour_label
        ])

print("minute.csv generated successfully.")