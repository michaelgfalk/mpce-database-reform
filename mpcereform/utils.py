"""Useful objects and methods"""

import re
from datetime import date
import string

LETTER_VALUES = {letter:value for letter, value
                 in zip(string.ascii_uppercase, range(len(string.ascii_uppercase)))}

MONTHS = {
        'Jan':'01',
        'Feb':'02',
        'Mar':'03',
        'Apr':'04',
        'May':'05',
        'Jun':'06',
        'Jul':'07',
        'Aug':'08',
        'Sep':'09',
        'Oct':'10',
        'Nov':'11',
        'Dec':'12'
    }

def parse_date(date_string):
    """Parses date strings, allows for missing months and days"""

    # Frames for components
    year = '0000'
    month = '00'
    day = '00'

    if isinstance(date_string, str) and date_string != '': #pylint:disable=no-else-return;

        # Regexes to find components
        year_mtch = re.search(r'\b\d{4}\b', date_string)
        month_mtch = re.search(r'\b[A-Z][a-z]{2,8}\b', date_string)
        day_mtch = re.search(r'\b\d{1,2}(?=[a-z]{0,2}\b)', date_string)

        # Parse components
        if year_mtch:
            year = year_mtch.group(0)
        if month_mtch:
            month = MONTHS[month_mtch.group(0)[:3]]
        if day_mtch:
            day_digits = day_mtch.group(0)
            day = day[:-len(day_digits)] + day_digits

        # Validate
        try:
            date(int(year), int(month), int(day))
            return year + '-' + month + '-' + day
        except ValueError:
            return None

    return None

def convert_colname(colname):
    """Converts Excel column letter into python idx."""

    letters = [letter for letter in colname]

    # Initialise total
    total = 0

    # Add letters according to their place value
    # NB: It's a base 26 number system
    for i, letter in enumerate(letters):
        total += LETTER_VALUES[letter] * (26 ** i)

    return total
