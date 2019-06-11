"""Functions for copying data from the old database to the new."""

import mysql.connector as mysql
import re
from importlib.resources import read_text, path
from openpyxl import load_workbook

class LocalDB():
    """Class for managing connection to database server"""
    def __init__(self, user = 'root', host = '127.0.0.1', password = None):
        self.conn = mysql.connect(user = user, host = host, password = password)

        # Check databases exist
        cur = self.conn.cursor()
        cur.execute("SHOW DATABASES")
        db_list = [x[0] for x in cur.fetchall()]

        def check_for_dbs(msg = None):
            # Check for mpce
            if 'mpce' in db_list:
                if msg is None:
                    msg = "Existing MPCE database found. Overwrite? [y/n] "
                resp = input(msg)
                if resp == 'y':
                    print("Overwriting existing database...")
                    cur.execute("DROP DATABASE mpce")
                    self.create_new_db()
                elif resp == 'n':
                    pass
                else:
                    check_for_dbs("Overwrite existing MPCE database? Type 'y' or 'n': ")
            else:
                print("MPCE database not found. Creating it...")
                self.create_new_db()

            # Check for manuscripts
            if 'manuscripts' not in db_list:
                raise mysql.DatabaseError("Manuscripts database not found!")
    
        check_for_dbs()

    def create_new_db(self):
        """Rebuilds the new MPCE database from schema"""

        # Read in schema
        schema_raw = read_text('mpcereform.sql', 'mpce_database.sql')

        # Strip multiline comments
        # Use a non-greedy match, so it will find each seperate comment
        sql_com_rgx = re.compile(r'/\*.+?\*/', re.DOTALL)
        schema_stripped = sql_com_rgx.sub('', schema_raw)

        # Split on semicolons
        schema_split = schema_stripped.split(';')

        # Execute
        cur = self.conn.cursor()
        for stmt in schema_split:
            cur.execute(stmt)
        self.conn.commit()
        cur.close()

    def import_works(self):
        """Copies works from old db to new"""

        # New cursor
        cur = self.conn.cursor()

        # Copy basic data directly from manuscript_books
        print("Importing works...")
        cur.execute("""
            INSERT INTO mpce.work (
                work_code, work_title, parisian_keyword, illegality_notes
            )
            SELECT super_book_code, super_book_title, parisian_keyword, illegality
            FROM manuscripts.manuscript_books
            """
        )
        self.conn.commit()
        print(f'{cur.rowcount} works copied.')
        
        # Copy categorisation data
        print("Processing keywords...")
        cur.execute("""
            UPDATE mpce.work AS w, manuscripts.manuscript_cat_fuzzy AS cf
            SET
                w.categorisation_fuzzy_value = cf.fuzzyValue,
                w.categorisation_notes = cf.fuzzyComment
            WHERE w.work_code = cf.super_book_code
            """
        )

        # Break keywords out into join table
        # Keyword assignments are comma-seperated values in 'manuscripts'
        cur.execute("""
            SELECT super_book_code, keywords
            FROM manuscripts.manuscript_books
            WHERE CHAR_LENGTH(keywords) > 1
        """)
        keywords = cur.fetchall()
        keywords_split = []
        for sbk, kwds in keywords:
            for kwd in kwds.split(','):
                keywords_split.append((sbk, kwd))
        cur.executemany("""
            INSERT INTO mpce.work_keyword (work_code, keyword_code)
            VALUES (%s, %s)
        """, keywords_split)
        self.conn.commit()
        print(f'{cur.rowcount} keyword assignments copied.')

        # Import rest of keyword data
        cur.execute("""
            INSERT INTO mpce.parisian_category
            SELECT * FROM manuscripts.parisian_keywords
        """)
        cur.execute("""
            INSERT INTO mpce.keyword
            SELECT * FROM manuscripts_keyword
        """)
        cur.execute("""
            INSERT INTO mpce.tag
            SELECT * FROM manuscripts.tags
        """)
        self.conn.commit()
        print('Parisian categories, keywords and tags imported.')

        # Import keyword associations (need some massaging)
        cur.execute("""
            INSERT INTO mpce.keyword_free_associations (keyword_1, keyword_2)
            SELECT k1.keyword_code AS keyword_1, k2.keyword_code AS keyword_2
            FROM manuscripts.keywords AS k1, manuscripts.keywords AS k2, keyword_free_associations AS ka
            WHERE
	            k1.keyword = ka.keyword AND
	            k2.keyword = ka.association
        """)
        cur.execute("""
            INSERT INTO mpce.keyword_tree_associations (keyword_1, keyword_2)
            SELECT k1.keyword_code AS keyword_1, k2.keyword_code AS keyword_2
            FROM manuscripts.keywords AS k1, manuscripts.keywords AS k2, keyword_tree_associations AS ka
            WHERE
                k1.keyword = ka.keyword AND
                k2.keyword = ka.association
        """)
        self.conn.commit()
        print('Keyword associations imported.')

        # Close cursor
        cur.close()

    def import_editions(self):
        """Imports edition data from manuscripts db"""

        # Open cursor
        cur = self.conn.cursor()

        cur.execute("""
            INSERT INTO mpce.edition (
                edition_code, work_code, edition_status, edition_type,
                full_book_title, short_book_titles, translated_title,
                translated_language, languages, imprint_publishers,
                actual_publishers, imprint_publication_places, 
                actual_publication_places, imprint_publication_years,
                actual_publication_years, pages, quick_pages,
                number_of_volumes, section, edition, book_sheets,
                notes, research_notes
            )
            SELECT book_code, super_book_code, edition_status,
                edition_type, full_book_title, short_book_titles,
                translated_title, translated_language, languages,
                stated_publishers, actual_publishers,
                stated_publication_places, actual_publication_places,
                stated_publication_years, actual_publication_years,
                pages, quick_pages, number_of_volumes, section,
                edition, book_sheets, notes, research_notes
            FROM manuscripts.manuscripts_books_editions
        """)

    def resolve_agents(self):
        """Imports persons and corporate entities.
        
        This method reforms all the person data in the database,
        based on the information in the manuscripts database, and 
        in the provided spreadsheets."""

        cur = self.conn.cursor()
        
        # Import basic client and person data
        print('Importing existing client and person data...')
        cur.execute("""
            INSERT INTO mpce.person (
                person_code, name, sex, title, other_names,
                designation, status, birth_date, death_date,
                notes
            )
            SELECT person_code, person_name, sex, title, other_names,
                designation, status, birth_date, death_date,
                notes
            FROM manuscripts.people
        """)
        print(f'{cur.rowcount()} persons imported from `manuscripts.people` into `mpce.person`.')
        cur.execute("""
            INSERT INTO mpce.stn_client
            SELECT * FROM manuscripts.clients
        """)
        print(f'{cur.rowcount} clients imported from `manuscripts.clients` into `mpce.stn_client`.' )

        # Import author data
        print('Resolving authors...')
        with path('mpcereform.spreadsheets', 'author_person.xlsx') as path:
            author_person = load_workbook(path, read_only = True, keep_vba = False)
        # Get list of all authors who already have person codes
        assigned_authors = []
        for row in author_person.iter_rows():
            # If the match is correct...
            if row[6] == 'Y':
                # ... append (person_code, author_code)
                assigned_authors.append((row[0], row[2]))
        
        # Create temporary author_person table
        cur.execute("""
            CREATE TEMPORARY TABLE mpce.author_person (
                person_code CHAR(6),
                author_code CHAR(9),
                PRIMARY KEY(author code, person_code)
            )
        """)
        cur.executemany("""
            INSERT INTO mpce.author_person
            VALUES (%s, %s)
        """, seq_of_params = assigned_authors)
        self.conn.commit()
        print(f'{cur.rowcount} authors already have person codes.')

        # Get all the authors without a person code
        cur.execute("""
            SELECT a.author_name
            FROM mpce.author_person AS ap
            LEFT JOIN manuscripts.authors AS a
                ON ap.author_code = a.author_code
            WHERE ap.person_code IS NULL
        """)
        unassigned_authors = cur.fetchall()
        new_person_codes = self._get_person_code_sequence(len(unassigned_authors), cur)
        cur.executemany("""
            INSERT INTO mpce.person (person_code, name)
            VALUES (%s, %s)
        """, seq_of_params = [(code, name) for code, (name,) in zip(new_person_codes, unassigned_authors)])
        print(f'{cur.rowcount} authors assigned new person codes...')
        self.conn.commit()

        # Now import authorship data 
        # TO DO

    def _get_person_code_sequence(self, n, cursor = None):
        """Return a list of the next n free person_codes"""

        # Regex to reduce the ids to their numerical components
        reduce_id_rgx = re.compile(r'^id0*')

        # Get a cursor
        if cursor is not None:
            cur = cursor
        else:
            cur = self.conn.cursor()
        
        # Retrieve person codes, strip 'id' and leading 0s, convert to int
        cur.execute("SELECT person_code FROM mpce.person")
        person_codes = cur.fetchall()
        person_codes = [int(reduce_id_rgx.sub('', id)) for id in person_codes]
        
        # Get the maximum numeric id
        next_id = max(person_codes) + 1

        # Return list of codes
        frame = 'id0000'
        return [frame[:-len(str(id))] + str(id) for id in range(next_id, next_id + n)]


        

    
