"""Command for reshaping existing 'manuscripts' database, and porting it to the new structure"""
import sys
from mpcereform.core import LocalDB

def main():
    """Main entry point for the script"""

    # Start connection, build schema if necessary
    print('\nDATABASE CONNECTION')
    print('======================\n')
    db = LocalDB() #pylint:disable=invalid-name;

    # Run import methods
    print('\nENTITY IMPORT')
    print('======================\n')
    db.import_works()
    db.import_editions()
    db.import_places()

    print('\nEVENT IMPORT')
    print('======================\n')
    db.import_stn()
    db.import_new_tables()
    db.import_data_spreadsheets()

    print('\nRESOLVING AGENT DATA')
    print('======================\n')
    db.resolve_agents()

    db.summarise()

if __name__ == '__main__':
    sys.exit(main())
