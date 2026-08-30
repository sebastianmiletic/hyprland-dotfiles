#!/usr/bin/env python3
"""Import an iCalendar timetable into Quickshell's compact weekly model."""

import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from zoneinfo import ZoneInfo

DAY_INDEX = {"SU": 0, "MO": 1, "TU": 2, "WE": 3, "TH": 4, "FR": 5, "SA": 6}


def unfold(text):
    lines = []
    for raw in text.replace("\r\n", "\n").replace("\r", "\n").split("\n"):
        if raw.startswith((" ", "\t")) and lines:
            lines[-1] += raw[1:]
        else:
            lines.append(raw)
    return lines


def unescape(value):
    return (value.replace("\\n", " ").replace("\\N", " ")
            .replace("\\,", ",").replace("\\;", ";").replace("\\\\", "\\").strip())


def parse_property(line):
    if ":" not in line:
        return None, {}, ""
    head, value = line.split(":", 1)
    parts = head.split(";")
    params = {}
    for part in parts[1:]:
        if "=" in part:
            key, param_value = part.split("=", 1)
            params[key.upper()] = param_value.strip('"')
    return parts[0].upper(), params, value


def parse_datetime(value, params):
    value = value.strip()
    if not value:
        return None
    is_utc = value.endswith("Z")
    plain = value[:-1] if is_utc else value
    formats = ("%Y%m%dT%H%M%S", "%Y%m%dT%H%M", "%Y%m%d")
    parsed = None
    for fmt in formats:
        try:
            parsed = datetime.strptime(plain, fmt)
            break
        except ValueError:
            pass
    if parsed is None:
        return None
    if is_utc:
        return parsed.replace(tzinfo=timezone.utc).astimezone()
    tzid = params.get("TZID", "")
    if tzid:
        try:
            return parsed.replace(tzinfo=ZoneInfo(tzid)).astimezone()
        except Exception:
            pass
    return parsed


def parse_until(rrule):
    match = re.search(r"(?:^|;)UNTIL=([^;]+)", rrule)
    if not match:
        return ""
    parsed = parse_datetime(match.group(1), {})
    return parsed.strftime("%Y-%m-%d") if parsed else ""


def parse_events(source):
    events = []
    current = None
    for line in unfold(source):
        if line == "BEGIN:VEVENT":
            current = {}
            continue
        if line == "END:VEVENT":
            if current is not None:
                events.append(current)
            current = None
            continue
        if current is None:
            continue
        name, params, value = parse_property(line)
        if not name:
            continue
        if name in ("DTSTART", "DTEND"):
            current[name] = parse_datetime(value, params)
        elif name in ("SUMMARY", "LOCATION", "UID", "RRULE", "STATUS"):
            current[name] = unescape(value)
    return events


def normalize(events, source_path):
    output = []
    seen = set()
    for number, event in enumerate(events):
        start = event.get("DTSTART")
        if not start or event.get("STATUS", "").upper() == "CANCELLED":
            continue
        end = event.get("DTEND")
        rrule = event.get("RRULE", "")
        byday_match = re.search(r"(?:^|;)BYDAY=([^;]+)", rrule)
        day_codes = byday_match.group(1).split(",") if byday_match else []
        days = []
        for code in day_codes:
            code = re.sub(r"^[+-]?\d+", "", code.upper())
            if code in DAY_INDEX and DAY_INDEX[code] not in days:
                days.append(DAY_INDEX[code])
        if not days:
            # Python Monday=0; JavaScript Sunday=0.
            days = [(start.weekday() + 1) % 7]
        recurring = bool(rrule)
        valid_from = start.strftime("%Y-%m-%d")
        valid_until = parse_until(rrule)
        for day in days:
            uid = event.get("UID") or f"event-{number}"
            item_id = f"{uid}:{day}:{start.strftime('%H%M')}"
            if item_id in seen:
                continue
            seen.add(item_id)
            output.append({
                "id": item_id,
                "title": event.get("SUMMARY") or "Untitled class",
                "room": event.get("LOCATION", ""),
                "day": day,
                "start": start.strftime("%H:%M"),
                "end": end.strftime("%H:%M") if end else "",
                "validFrom": valid_from,
                "validUntil": valid_until,
                "singleDate": "" if recurring else valid_from,
                "source": str(source_path),
            })
    return sorted(output, key=lambda item: (item["day"], item["start"], item["title"].lower()))


def main():
    if len(sys.argv) != 3:
        raise SystemExit("usage: import-ics.py INPUT.ics OUTPUT.json")
    source_path = Path(sys.argv[1]).expanduser().resolve()
    output_path = Path(sys.argv[2]).expanduser().resolve()
    if source_path.suffix.lower() not in (".ics", ".ical"):
        raise ValueError("Please choose an .ics calendar file")
    events = normalize(parse_events(source_path.read_text(encoding="utf-8-sig", errors="replace")), source_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    temporary = output_path.with_suffix(output_path.suffix + ".tmp")
    temporary.write_text(json.dumps(events, indent=2, ensure_ascii=False), encoding="utf-8")
    os.chmod(temporary, 0o600)
    temporary.replace(output_path)
    print(json.dumps({"status": "imported", "count": len(events), "source": str(source_path)}))


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(json.dumps({"status": "error", "message": str(error)}))
        raise SystemExit(1)
