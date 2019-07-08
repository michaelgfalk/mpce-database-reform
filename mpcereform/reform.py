"""Command for reshaping existing 'manuscripts' database, and porting it to the new structure"""
import sys
import argparse
from mpcereform.core import LocalDB

def main():
    """Main entry point for the script"""

    # Define argument parser
    parser = argparse.ArgumentParser(description='Build the MPCE database from raw data.')
    parser.add_argument('-u', '--user', type=str,
                        help='username for your MySQL/MariaDB server', default='root')
    parser.add_argument('-p', '--password', type=str,
                        help='password for your MySQL/MariaDB server', default=None)
    parser.add_argument('-hst', '--host', type=str,
                        help='hostname for your MySQL/MariaDB server (defaults to localhost)',
                        default='127.0.0.1')

    args = parser.parse_args()

    arg_dict = vars(args)

    # Start connection, build schema if necessary
    print('\nDATABASE CONNECTION')
    print('======================\n')
    db = LocalDB(**arg_dict) #pylint:disable=invalid-name;

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
