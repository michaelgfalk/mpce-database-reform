"""Command for reshaping existing 'manuscripts' database, and porting it to the new structure"""
import sys
from mpcereform.core import LocalDB

def main():
    """Main entry point for the script"""

    # Start connection, build schema if necessary
    db = LocalDB()
    
    # Run import methods
    db.import_works()
    db.import_editions()
    db.import_places()
    db.import_stn()
    db.import_new_tables()
    db.resolve_agents()
    # db.import_data_spreadsheets()

if __name__ == '__main__':
    sys.exit(main())
