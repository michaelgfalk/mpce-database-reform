"""Command for reshaping existing 'manuscripts' database, and porting it to the new structure"""
import sys
from mpcereform.core import LocalDB

def main():
    """Main entry point for the script"""

    # Start connection, build schema if necessary
    db = LocalDB()

    # Copy works
    db.import_works()

if __name__ == '__main__':
    sys.exit(main())