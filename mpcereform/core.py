"""Functions for copying data from the old database to the new."""

import mysql.connector as mysql
import re
from importlib.resources import read_text, path
from openpyxl import load_workbook

class LocalDB():
    """Class for managing connection to database server"""

    UNCHANGED_TABLES = {
        # Tables identical to their STN counterparts
        'mpce.stn_client': 'manuscripts.clients',
        'mpce.stn_client_person': 'manuscripts.clients_people',
        'mpce.stn_client_profession': 'manuscripts.clients_professions',
        'mpce.stn_edition_call_number': 'manuscripts.books_call_numbers',
        'mpce.stn_edition_catalogue': 'manuscripts.books_stn_catalogues',
        'mpce.stn_client_correspondence_ms': 'manuscripts.clients_correspondence_manuscripts',
        'mpce.stn_client_correspondence_place': 'manuscripts.clients_correspondence_places',
        'mpce.stn_order': 'manuscripts.orders',
        'mpce.stn_order_agent': 'manuscripts.orders_agents',
        'mpce.stn_order_sent_via': 'manuscripts.orders_sent_via',
        'mpce.stn_order_sent_via_place': 'manuscripts.orders_sent_via_place',
        'mpce.stn_transaction_volumes_exchanged': 'manuscripts.transactions_volumes_exchanged'
    }

    TRANSACTION_CODING = {
        # Codes for STN transactions
        'in':1,
        'in (printing)':1,
        'out':2,
        'out (free gifts)':2,
        'out (transfer)':2,
        'in (transfer)':1,
        'in (return)':1,
        'out (lost)':2,
        'out (return)':2,
        'stock take':3,
        'out (other)':2,
        'in (found)':1,
        'out (profit and loss)':2,
        'in (recount)':1,
        'out (missing)':2,
        'in (other)':1,
        'out (binders)':2,
        'bilan de sortie':3,
        'bilan':3,
        'out (faults)':2,
        'in (profit and loss)':1,
        'out (inferred)':2,
        'sales ms1003':3,
        'returned before arrival':1,
        'in (rétiré)':1,
        'catalogue':3,
        'out (durand commission)':2,
        'commission':3,
        'in (durand commission)':1,
        'in (assumed printing)':1,
        'bilan (adjustment)':3
    }

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
            SELECT * FROM manuscripts.keywords
        """)
        cur.execute("""
            INSERT INTO mpce.tag
            SELECT * FROM manuscripts.tags
        """)
        self.conn.commit()
        print('Parisian categories, keywords and tags imported.')

        # Import keyword associations (need some massaging)
        cur.execute("""
            INSERT IGNORE INTO mpce.keyword_free_association (keyword_1, keyword_2)
            SELECT k1.keyword_code AS keyword_1, k2.keyword_code AS keyword_2
            FROM manuscripts.keyword_free_associations AS ka
                LEFT JOIN manuscripts.keywords AS k1
                    ON k1.keyword = ka.keyword
                LEFT JOIN manuscripts.keywords AS k2
                    ON k2.keyword = ka.association
        """)
        cur.execute("""
            INSERT IGNORE INTO mpce.keyword_tree_association (keyword_1, keyword_2)
            SELECT k1.keyword_code AS keyword_1, k2.keyword_code AS keyword_2
            FROM manuscripts.keyword_tree_associations AS ka
                LEFT JOIN manuscripts.keywords AS k1
                    ON k1.keyword = ka.keyword
                LEFT JOIN manuscripts.keywords AS k2
                    ON k2.keyword = ka.association
        """)
        self.conn.commit()
        print('Keyword associations imported.')

        # Close cursor
        cur.close()

    def import_editions(self):
        """Imports edition data from manuscripts db"""

        # Open cursor
        cur = self.conn.cursor()

        print(f'Importing editions from `manuscript_books_editions`...')
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
            FROM manuscripts.manuscript_books_editions
        """)
        print(f'{cur.rowcount} editions imported into `edition`.')
        self.conn.commit()
        cur.close()

    def import_stn(self):
        """Imports STN data from FBTEE-1"""

        cur = self.conn.cursor()

        # Port unchanged tables across
        print('Transferring unchanged STN data...')
        for mpce, man in self.UNCHANGED_TABLES.items():
            cur.execute(f'INSERT INTO {mpce} SELECT * FROM {man}')
            print(f'Data from `{man}` transferred to `{mpce}`.')
        self.conn.commit()
        
        print('Unchanged STN data imported. Importing transactions...')
        
        # Port transaction data across
        cur.execute("""
            CREATE TEMPORARY TABLE mpce.trans_type_key (
                name VARCHAR(255) PRIMARY KEY,
                id INT
            )
        """)
        cur.executemany("""
            INSERT INTO trans_type_key
            VALUES (%s, %s)
        """, seq_params = [(name, id) for name, id in self.TRANSACTION_CODING.items()])
        # Copy data across with new coding
        cur.execute("""
            INSERT INTO mpce.stn_transaction (
                transaction_code, order_code, page_or_folio_numbers,
                account_heading, direction, transaction_description, work_code,
                edition_code, stn_abbreviated_title, total_number_of_volumes,
                notes
            )
            SELECT
                t.transaction_code, t.order_code, t.page_or_folio_numbers,
                t.account_heading, tc.id, t.direction_of_transaction, t.super_book_code,
                t.book_code, t.stn_abbreviated_title, t.total_number_of_volumes,
                t.notes
            FROM manuscripts.transactions AS t
            LEFT JOIN mpce.trans_type_key AS tc
                ON t.direction_of_transaction LIKE tc.name
        """)
        self.conn.commit()
        print(f'{cur.rowcount} transactions ported into `mpce.stn_transaction` with new direction coding.')

        # Finish
        cur.close()

    def import_new_tables(self):
        """Imports new MPCE data tables from manuscripts database."""

        cur = self.conn.cursor()

        print(f'Importing new datasets from manuscripts database ...')
        
        # L'estampillage de 1788
        cur.execute("""
            INSERT INTO mpce.stamping (
                ID, stamped_edition, permitted_dealer,
                attending_inspector, attending_adjoint,
                stamped_at_place, stamped_at_location_type,
                copies_stamped, volumes_stamped, date,
                ms_number, folio, citation, page_stamped,
                edition_notes, event_notes, article,
                date_entered, entered_by_user
            )
            SELECT
                ID, ID_EditionName, ID_DealerName,
                ID_AgentA, ID_AgentB,
                ID_PlaceName, EventLocation,
                EventCopies, EventVols, EventDate,
                ID_Archive, EventFolioPage, EventCitation, EventPageStamped,
                EventNotes, EventOther, EventArticle,
                DateEntered, EventUser
            FROM manuscripts.manuscript_events
        """)
        self.conn.commit()
        print(f'{cur.rowcount} stampings copied into `mpce.stamping`.')
        
        # Illegal books
        # First clean up date and title fields
        cur.execute("""
            UPDATE manuscripts.manuscript_titles_illegal
            SET date = NULL
            WHERE date = 'No date available'
        """)

        # Import banned books
        cur.execute("""
            INSERT INTO mpce.banned_list_record (
                UUID, work_code, title, author, date, folio, notes
            )
            SELECT
                UUID, illegal_super_book_code, illegal_full_book_title, illegal_author_name,
                illegal_date, illegal_folio, illegal_notes
            FROM manuscripts.manuscript_titles_illegal
            WHERE
                record_status <> 'DELETED' AND
                bastille_book_category == ''
        """)
        print(f'{cur.rowcount} banned books added to `mpce.banned_list_record`.')
        self.conn.commit()
        
        # Import bastille register records
        # Index to speed up import:
        cur.execute("""
            CREATE INDEX book_sbc 
            ON manuscripts.manuscript_books_editions (super_book_code)
        """)
        cur.execute("""
            INSERT INTO mpce.bastille_register_record (
                UUID, edition_code, work_code, title, 
                author_name, imprint, publication_year,
                copies_found, current_volumes, total_volumtes,
                category, notes
            )
            SELECT i.UUID, b.book_code, i.illegal_super_book_code, i.illegal_full_book_title, 
                i.illegal_author_name, i.bastille_imprint_full, i.illegal_date, 
                i.bastille_copies_number, i.bastille_current_volumes, i.bastille_total_volumes,
                i.bastille_book_category, i.illegal_notes
            FROM manuscripts.manuscript_titles_illegal AS i
            LEFT JOIN manuscripts.manuscript_books_editions AS b
                ON  i.illegal_super_book_code = b.super_book_code AND
                    (i.illegal_date = b.actual_publication_years OR
                     i.illegal_date = b.stated_publication_years) 
        """)
        print(f'{cur.rowcount} bastille register records added to `mpce.bastille_register_record`.')
        self.conn.commit()

        # Parisian stock auctions
        cur.execute("""
            INSERT INTO mpce.parisian_stock_auction (
                auction_id, ms_number, previous_owner, auction_reason, place
            )
            SELECT salesNumber, msNumber, Client_Code, code, Place_Code
            FROM manuscripts.manuscript_sales_events
        """)
        print(f'{cur.rowcount} stock auctions addded to `mpce.parisian_stock_auction`.')
        self.conn.commit()

        # Auction administrators
        auction_rgx = re.compile(r'(c[a-z][0-9]{4}) \((\w+)\)')

        # Get all the administrators
        cur.execute('SELECT salesNumber, ID_Agent FROM manuscripts.manuscript_sales_events')
        administrators = cur.fetchall()
        
        # Make dict of auction_roles
        cur.execute('SELECT * FROM auction_role')
        auction_roles = cur.fetchall()
        auction_roles = {role:id for id,role in auction_roles}
        
        # Split and flatten
        auction_administrator = []
        for sale, agents in administrators:
            # Extract data from string and append to list
            for agent in agents.split(','):
                mtch = auction_rgx.search(agent)
                person = mtch.group(1)
                role = auction_roles[mtch.group(2)]
                auction_administrator.append((sale, person, role))
        cur.executemany(
            'INSERT INTO mpce.auction_administrator VALUES (%s, %s, %s,)',
            seq_params = auction_administrator
        )
        print(f'{cur.rowcount} administration roles added to `mpce.auction_administrator`.')
        self.conn.commit()

        # Import individual sales
        cur.execute("""
            INSERT INTO mpce.parisian_stock_sale (
                ID, auction_id, purchasher,
                purchased_edition, sale_type,
                units_sold, units, volumes_traded,
                lot_price, date, folio,
                citation, article_number, edition_notes,
                event_notes, sale_notes
            )
            SELECT
                ss.ID, ss.ID_SaleAgent, ss.ID_DealerName,
                ss.ID_EditionName, st.ID,
                ss.EventCopies,
                CASE WHEN EventCopiesType = 'packet' THEN 5,
                    WHEN EventCopiesType = 'copies' THEN 3,
                    WHEN EventCopiesType = 'privilege' THEN 8,
                    WHEN EventCopiesType = 'plates' THEN 6,
                    WHEN EventCopiesType = 'basket' THEN 4,
                    WHEN EventCopiesType = 'vols' THEN 9,
                    WHEN EventCopiesType = 'crate' THEN 2
                    ELSE NULL
                    END AS units,
                EventVols, EventLotPrice, EventDate, EventFolioPage,
                EventCitation, EventArticle, EventNotes,
                EventOther, EventMoreNotes
            FROM manuscripts.manuscript_events_sales AS ss
            LEFT JOIN mpce.sale_type AS st
                ON ss.sale_type = st.type
        """)
        print(f'{cur.rowcount} sales added to `mpce.parisian_stock_sale`.')
        self.conn.commit()

        # Finish
        cur.close()

    def import_data_spreadsheets(self):
        """Imports major data spreadsheets from MPCE."""
        pass

    def resolve_agents(self):
        """Resolves references to persons and corporate entities in the database.
        
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
        print(f'{cur.rowcount} persons imported from `manuscripts.people` into `mpce.person`.')
        
        # Import agent metadata
        cur.execute("""
            INSERT INTO mpce.profession
            SELECT * FROM manuscripts.professions
        """)
        cur.execute("""
            INSERT INTO mpce.person_profession
            SELECT * FROM manuscripts.people_professions
        """)

        # Import author data
        print('Resolving authors...')
        with path('mpcereform.spreadsheets', 'author_person.xlsx') as p:
            author_person = load_workbook(p, read_only = True, keep_vba = False)
        # Get list of all authors who already have person codes
        assigned_authors = []
        for row in author_person['author_person'].iter_rows(min_row = 2, values_only = True):
            # If the match is correct...
            if row[7] == 'Y':
                # ... append (person_code, author_code)
                # Assumes that the workbook has the following columns in sheet 0:
                # person_code, client_code, person_name, author_code, author_name, osa, cosine, correct, notes
                assigned_authors.append((row[0], row[3]))
        # Create temporary author_person table
        cur.execute("""
            CREATE TEMPORARY TABLE mpce.author_person (
                person_code VARCHAR(255),
                author_code VARCHAR(255),
                PRIMARY KEY(author_code, person_code)
            )
        """)
        cur.executemany("""
            INSERT INTO mpce.author_person
            VALUES (%s, %s)
        """, seq_params = assigned_authors)
        self.conn.commit()
        print(f'{cur.rowcount} authors with person_codes found in spreadsheet.')

        # Create new persons for all authors without a person_code
        cur.execute("""
            SELECT a.author_name, a.author_code
            FROM mpce.author_person AS ap
            LEFT JOIN manuscripts.manuscript_authors AS a
                ON ap.author_code = a.author_code
            WHERE ap.person_code IS NULL
        """)
        unassigned_auths = cur.fetchall()
        n = len(unassigned_auths)
        new_pcs = self._get_code_sequence('manuscripts.people','person_code','id0000', n, cur)
        cur.executemany("""
            INSERT INTO mpce.person (person_code, name)
            VALUES (%s, %s)
        """, seq_params=[(p_cd, name) for p_cd, (name, a_cd) in zip(new_pcs, unassigned_auths)])
        cur.executemany("""
            INSERT INTO mpce.author_person (author_code, person_code)
            VALUES (%s, %s)
        """, seq_params=[(a_cd, p_cd) for p_cd, (name, a_cd) in zip(new_pcs, unassigned_auths)])

        print(f'{cur.rowcount} authors assigned new person codes...')
        self.conn.commit()

        # Now import authorship data 
        cur.execute("""
            INSERT INTO mpce.edition_author (
                edition_code, author, author_type, certain
            )
            SELECT ba.book_code, ap.person_code, at.id, ba.certain
                FROM manuscripts.manuscript_books_authors AS ba
                LEFT JOIN mpce.author_person AS ap
                    ON ba.author_code = ap.author_code
                LEFT JOIN mpce.author_type AS at
                    ON ba.author_type LIKE at.type
        """)
        print(f'All authors resolved into persons. {cur.rowcount} authorship attributions imported into `mpce.edition_author`.')
        self.conn.commit()

        # TO DO: Apply new profession code to all authors

        # 

        # Finish
        cur.close()

    def build_indexes(self):
        """Builds key indexes for common queries."""
        pass

    # Utility methods
    def _get_code_sequence(self, table, column, frame, n, cursor = None):
        """Return a list of the next n free person_codes
        
        Arguments:
        ==========
            table (str): name of table to be queried
            column (str): name of column to be queried
            frame (str): blank version of id code, e.g. 'pl0000' for a place_code
            n (int): number of new ids to be generated
            cursor (MySQLCursor): a cursor, if you don't wish to create a new one

        Returns:
        ==========
            A sequence of n new codes
        """

        # Regex for extracting numeric part of id
        num_extr_rgx = re.compile(r'[1-9]\d*')

        # Get a cursor
        if cursor is not None:
            cur = cursor
        else:
            cur = self.conn.cursor()
        
        # Retrieve person codes, strip 'id' and leading 0s, convert to int
        cur.execute(f'SELECT {column} FROM {table}')
        codes = cur.fetchall()
        codes = [int(num_extr_rgx.search(id).group(0))
                 for (id,) in codes]
        
        if cursor is None:
            cur.close()

        # Get the maximum numeric id
        next_id = max(codes) + 1

        # Return list of codes
        return [frame[:-len(str(id))] + str(id) for id in range(next_id, next_id + n)]


        

    
