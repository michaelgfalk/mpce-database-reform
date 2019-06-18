"""Useful objects and methods"""

import re

def parse_date(string):
    """Parses date strings, allows for missing months and days"""

    months = {
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

    # Frames for components
    year = '0000'
    month = '00'
    day = '00'

    if type(string) == str:

        # Regexes to find components
        year_mtch = re.search(r'\b\d{4}\b', string)
        month_mtch = re.search(r'\b[A-Z][a-z]{2,8}\b', string)
        day_mtch = re.search(r'\b\d{1,2}(?=[a-z]{0,2}\b)', string)

        # Parse components
        if year_mtch:
            year = year_mtch.group(0)
        if month_mtch:
            month = months[month_mtch.group(0)[:3]]
        if day_mtch:
            day_digits = day_mtch.group(0)
            day = day[:-len(day_digits)] + day_digits

        return(year + '-' + month + '-' + day)
    
    else:
        return None
