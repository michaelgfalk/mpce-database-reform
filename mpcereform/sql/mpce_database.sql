/*
===========================================================
 ___      ___   ____________   ____________   ____________
|   \    /   | |            | |            | |            |
|    \  /    | |   ______   | |   _________| |   _________|
|  \  \/  /  | |  |______|  | |  |           |  |______
|  |\    /|  | |            | |  |           |   ______|
|  | \__/ |  | |  __________| |  |           |  |
|  |      |  | |  |           |  |_________  |  |_________
|  |      |  | |  |           |            | |            |
|__|      |__| |__|           |____________| |____________|

===========================================================

MPCE DATABASE SCHEMA

AUTHOR: Michael Falk

Table definitions for entire MPCE database, including MMF-2.

The python module of which this forms a part contains methods for
importing the data from the existing 'manuscripts database'.

*/

/*

# SECTION 1: OPEN CONNECTION, CREATE AND USE DATABASE

*/
SET NAMES utf8;
CREATE DATABASE mpce;
USE mpce;

/*

# SECTION 2: ENTITIES

The primary entities in the MPCE database are books, agents and places. All the
events recorded in the data concern these kinds of entity.

## 2.1	Books

There are two kinds of book in the database:
-	The 'work', formerly known as the 'super_book', which represents the abstract
	idea of the book, of which each concrete book is an example
-	The 'edition', formerly known as the 'book', which represents a particular
	concrete instantiation of a given 'work'.

NB: In our data, we do not distinguish between the 'work' and the 'expression' (or
version), as in the FRBR classification. Likewise, we do not systematically
record information about individual 'items'. Most of our data can only tell us
which edition ('manifestation' in FRBR terms) was at play.

In addition, works are categorised by keywords. Each work is assigned a single
parisian booksellers' category, and can be assigned an arbitrary number of
keywords in the FBTEE system.

*/

CREATE TABLE IF NOT EXISTS work ( -- From manuscript_books [super_books in original STN db]
	/*
	This is the new version of the `super_books` table. Both the table and the key
	column have been renamed 'work'.
	In the transition to the new database in c. 2016, the data type was changed.
	Originally, the super_book_code was a string of fixed length 11. It was
	lengthened to 12.
	*/
	`work_code` CHAR(12) NOT NULL,
	`work_title` VARCHAR(750) NOT NULL,
	`parisian_keyword` VARCHAR(2000) DEFAULT NULL,
	`illegality_notes` VARCHAR(2000) DEFAULT NULL,
	`categorisation_fuzzy_value` INT DEFAULT 0,
	`categorisation_notes` TEXT,
	PRIMARY KEY (`work_code`)
);

CREATE TABLE IF NOT EXISTS edition ( -- From manuscript_books_editions [books in original STN db]
	/*
	This is the new version of the `books` table. It has been renamed `edition`.
	The data type of `edition_code` is now CHAR(12), a change from CHAR(9) in the
	original STN database.
	*/
	`edition_code` CHAR(12) NOT NULL,
	`work_code` CHAR(12) NOT NULL,
	`edition_status` VARCHAR(15),
	`edition_type` VARCHAR(50),
	`full_book_title` VARCHAR(750),
	`short_book_titles` VARCHAR(1000),
	`translated_title` VARCHAR(750),
	`translated_language` VARCHAR(50),
	`languages` VARCHAR(200),
	`imprint_publishers` VARCHAR(1000),
	`actual_publishers` VARCHAR(1000),
	`imprint_publication_places` VARCHAR(1000),
	`actual_publication_places` VARCHAR(1000),
	`imprint_publication_years` VARCHAR(1000),
	`actual_publication_years` VARCHAR(10),
	`pages` VARCHAR(250),
	`quick_pages` VARCHAR(10),
	`number_of_volumes` INT(11),
	`section` VARCHAR(10),
	`edition` VARCHAR(100),
	`book_sheets` VARCHAR(200),
	`known_pirated` BIT DEFAULT 0,
	`notes` VARCHAR(4000),
	`research_notes` VARCHAR(1000),
	PRIMARY KEY (`edition_code`)
);

-- Book classification tables

CREATE TABLE IF NOT EXISTS parisian_category (
	`parisian_category_code` CHAR(5) NOT NULL,
	`name` VARCHAR(250) NOT NULL,
	`ancestor1` CHAR(5),
	`ancestor2` CHAR(5),
	`ancestor3` CHAR(5),
	PRIMARY KEY (`parisian_category_code`)
);

CREATE TABLE IF NOT EXISTS keyword (
	`keyword_code` CHAR(5) NOT NULL,
	`keyword` VARCHAR(250),
	`definition` VARCHAR(1000),
	`tag_code` CHAR(3),
	PRIMARY KEY (`keyword_code`)
);

CREATE TABLE IF NOT EXISTS keyword_fuzzy_values (
	`fuzzy_value_code` INT NOT NULL,
	`fuzzy_value` VARCHAR(50),
	PRIMARY KEY (`fuzzy_value_code`)
);
INSERT INTO
	`keyword_fuzzy_values`
VALUES
	(0,"No information exists on how this work was classified."),
	(1,"Classified on the basis of title alone."),
	(2,"Classified on basis of subject categorisations in library or other catalogues."),
	(3,"Classified after accounts in bibliographic sources, antiquarian booksellers catalogue descriptions, or other secondary source accounts."),
	(4,"Classified after inspection of a copy of the work."),
	(5,"Classified after thorough reading knowledge of the work."),
	(6,"Automatically classified.");
	
CREATE TABLE IF NOT EXISTS tag (
	`tag_code` CHAR(3),
	`tag` VARCHAR(50),
	`tag_definition` VARCHAR(1000),
	PRIMARY KEY (`tag_code`)
);

CREATE TABLE IF NOT EXISTS work_keyword (
	`work_code` CHAR(12),
	`keyword_code` CHAR(5),
	PRIMARY KEY (`work_code`,`keyword_code`)
);

/*
Unfortunately these two association tables were created using the keyword
names, rather than the keyword codes... This will need to be transformed.
*/
CREATE TABLE IF NOT EXISTS keyword_free_association (
	keyword_1 CHAR(5),
	keyword_2 CHAR(5),
	PRIMARY KEY (`keyword_1`, `keyword_2`)
);

CREATE TABLE IF NOT EXISTS keyword_tree_association (
	keyword_1 CHAR(5),
	keyword_2 CHAR(5),
	PRIMARY KEY (`keyword_1`, `keyword_2`)
);

/*

## 2.2	Agents

Agents have posed difficult problems in the development of the FBTEE database.
In the original STN database, a distinction was made between 'clients', which could
be people or organisations, and 'people', who could only be natural persons.
Moreover, the 'clients' table of the original STN database recorded lots of
information about how a particular client was related to the STN.

As the project expanded, numerous seperate tables of persons were created. In
addition, new agents were assigned new client_codes as a matter of course, rather
than person_codes. No decision was made about how to treat organisations that
were not clients of the STN.

In this schema, a thorough revamp is proposed. The 'clients' table will be frozen
in its original form, meaning the production database will contain a discrete list
of all clients of the STN. The person table (renamed from the original 'people'
table) will be updated to include the details of every person we have encountered
in our datasets. A new corporate_entity table will be created to store information
about partnerships, government agencies etc.

*/

CREATE TABLE IF NOT EXISTS person ( -- From people
	`person_code` CHAR(6) NOT NULL,
	`name` VARCHAR(155) DEFAULT NULL,
	`sex` CHAR(1) DEFAULT NULL,
	`title` VARCHAR(50) DEFAULT NULL,
	`other_names` VARCHAR(1000) DEFAULT NULL,
	`designation` VARCHAR(50) DEFAULT NULL,
	`status` VARCHAR(50) DEFAULT NULL,
	`birth_date` DATE DEFAULT NULL,
	`death_date` DATE DEFAULT NULL,
	`notes` VARCHAR(4000) DEFAULT NULL,
	`cerl_id` CHAR(11),
	PRIMARY KEY (`person_code`)
);

CREATE TABLE IF NOT EXISTS corporate_entity ( -- New table
	`entity_code` INT(6) NOT NULL AUTO_INCREMENT,
	`entity_name` VARCHAR(155),
	`start_date` DATE,
	`end_date` DATE,
	`cerl_id` CHAR(11),
	`notes` TEXT,
	PRIMARY KEY (`entity_code`)
);

CREATE TABLE IF NOT EXISTS is_member_of ( -- New table
	`person_code` CHAR(6) NOT NULL,
	`entity_code` INT NOT NULL,
	PRIMARY KEY (`person_code`, `entity_code`)
);

-- Other types of person, and additional metadata

CREATE TABLE IF NOT EXISTS stn_client ( -- From clients
	`client_code` CHAR(6) NOT NULL,
	`client_name` VARCHAR(100),
	`has_correspondence` bit(1),
	`partnership` bit(1),
	`gender` VARCHAR(5),
	`data_source` VARCHAR(25) NOT NULL,
	`option_menu_type` VARCHAR(25) NOT NULL,
	`number_of_letters` smallint(6),
	`number_of_documents` smallint(6),
	`first_date` DATE,
	`last_date` DATE,
	`notes` VARCHAR(4000),
	PRIMARY KEY (`client_code`)
);

CREATE TABLE IF NOT EXISTS stn_client_person ( -- From clients_people
	`client_code` CHAR(6) NOT NULL,
	`person_code` CHAR(6) NOT NULL,
	PRIMARY KEY (`client_code`, `person_code`)
);

CREATE TABLE IF NOT EXISTS stn_client_profession ( -- From clients_professions
	`client_code` CHAR(6) NOT NULL,
	`profession_code` CHAR(6) NOT NULL,
	PRIMARY KEY(`client_code`, `profession_code`)
);

CREATE TABLE IF NOT EXISTS stn_client_corporate_entity( -- New table
	`client_code` CHAR(6) NOT NULL,
	`entity_code` CHAR(6) NOT NULL,
	PRIMARY KEY (`client_code`,`entity_code`)
);

CREATE TABLE IF NOT EXISTS profession ( -- From professions
	`profession_code` CHAR(5) NOT NULL,
	`profession_type` VARCHAR(50),
	`translated_profession` VARCHAR(100),
	`profession_group` VARCHAR(100),
	`economic_sector` VARCHAR(100),
	PRIMARY KEY(`profession_code`)
);

CREATE TABLE IF NOT EXISTS person_profession ( -- From people_professions
	`person_code` CHAR(6) NOT NULL,
	`profession_code` CHAR(5) NOT NULL,
	PRIMARY KEY (`person_code`, `profession_code`)
);

CREATE TABLE IF NOT EXISTS corporate_entity_profession ( -- New table
	`entity_code` CHAR(6) NOT NULL,
	`profession_code` CHAR(5) NOT NULL,
	PRIMARY KEY (`entity_code`, `profession_code`)
);

CREATE TABLE IF NOT EXISTS edition_author ( -- From manuscript_books_authors
	`edition_code` CHAR(12) NOT NULL,
	`author` CHAR(6) NOT NULL, -- Person code of the author
	`author_type` int NOT NULL,
	`certain` bit(1),
	PRIMARY KEY(`edition_code`, `author`, `author_type`)
);

CREATE TABLE IF NOT EXISTS author_type ( -- New table
	`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	`type` VARCHAR(20),
	`definition` TEXT
);
INSERT INTO `author_type` (`type`,`definition`)
VALUES
	("Primary","A person mainly responsible for the original content of the work."),
	("Secondary","A person who contributes to the original content of the work."),
	("Editor","A person who finds, selects, arranges or otherwise shapes the work, without primarily being responsible for its original content."),
	("Translator","A person who rewrites the work in a new language.");

/*

## 2.3	Places

The place data has been thoroughly checked and linked to geonames.

*/

CREATE TABLE IF NOT EXISTS place ( -- From manuscript_places
	`place_code` CHAR(5) NOT NULL,
	`name` VARCHAR(50),
	`alternative_names` VARCHAR(255),
	`town` VARCHAR(50),
	`C18_lower_territory` VARCHAR(50),
	`C18_sovereign_territory` VARCHAR(50),
	`C21_admin` VARCHAR(50),
	`C21_country` VARCHAR(50),
	`geographic_zone` VARCHAR(50),
	`BSR` VARCHAR(50),
	`HRE` BIT(1) NOT NULL,
	`EL` BIT(1) NOT NULL,
	`IFC` BIT(1) NOT NULL,
	`P` BIT(1) NOT NULL,
	`HE` BIT(1) NOT NULL,
	`HT` BIT(1) NOT NULL,
	`WT` BIT(1) NOT NULL,
	`PT` BIT(1) NOT NULL,
	`PrT` BIT(1) NOT NULL,
	`distance_from_neuchatel` DOUBLE,
	`latitude` DECIMAL(10,8),
	`longitude` DECIMAL(10,8),
	`geoname` INT(11),
	`notes` VARCHAR(1000),
	PRIMARY KEY (`place_code`)
);

CREATE TABLE IF NOT EXISTS person_address ( -- From clients_addresses
	`id` int NOT NULL AUTO_INCREMENT PRIMARY KEY,
	`person_code` CHAR(6) NOT NULL,
	`place_code` CHAR(5) NOT NULL,
	`address` VARCHAR(50),
	`from_date` DATE,
	`to_date` DATE
);

/*

## 2.4	Legacy Entity Data from the STN database

The original FBTEE database recorded a great deal of metadata about the STN's
archive. At a future time, it may be advisable to roll together all this
sort of data into a normalised set of tables for archival references. For the
moment, however, this old STN tables have been retained, and any relevant
archival references have been stored within the relevant data tables, without
normalisation.

*/

CREATE TABLE IF NOT EXISTS `stn_edition_call_number` ( -- From books_call_numbers
  `edition_code` CHAR(9) NOT NULL, -- Formerly book_code
  `call_number` VARCHAR(300) NOT NULL,
  PRIMARY KEY (`edition_code`,`call_number`)
);

CREATE TABLE IF NOT EXISTS `stn_edition_catalogue` ( -- From books_stn_catalogues
  `edition_code` CHAR(9) NOT NULL, -- Formerly book_code
  `catalogue` VARCHAR(200) NOT NULL,
  PRIMARY KEY (`edition_code`,`catalogue`)
);

CREATE TABLE IF NOT EXISTS `stn_client_correspondence_ms` ( -- From clients_correspondence_manuscripts
	`client_code` CHAR(6) NOT NULL,
	`position` INT NOT NULL,
	`manuscript_numbers` VARCHAR(500),
	PRIMARY KEY (`client_code`, `position`)
);

CREATE TABLE IF NOT EXISTS `stn_client_correspondence_place` ( -- From clients_correspondence_places
	`client_code` CHAR(6) NOT NULL,
	`place_code` CHAR(5) NOT NULL,
	`from_date` DATE,
	PRIMARY KEY(`client_code`, `place_code`)
);

/*

# SECTION 3: EVENTS

Book history is made up of events that happen to books. The MPCE database contains
information about a number of different events, that fall into two main categories:
-	The regulation of the book trade: In eighteenth-century France, books were
	inspected, confiscated, condemned, banned, and permitted. Various sources tell
	us when these different things happened to different books.
-	The production and exchange of books: Books were being manufactured, bought and
	sold all the time, of course. We have two main sources of such economic data in 
	our project: the records of the Parisian Stock Sales, large auctions that took
	place when booksellers stock had to be sold off, and the ledgers of the Société
	Typographique de Neuchâtel, the Swiss publisher that was the focus of FBTEE-1.

## 3.1	General Events Categorisation

MPCE is a hybrid database, somewhere in between a database of economic and social
data, and a detailed digital edition of certain historical manuscripts. Because
the decision has been made to capture all the idiosyncrasies of each historical
manuscript, there is not a clear and simple overall categorisation of events
in the database. Instead, each record in each document is treated as a particular
kind of event with its own unique set of data points.

Nonetheless, there are some features that several different documents have in
common, and which are shared in the below lookup tables.

*/

CREATE TABLE IF NOT EXISTS `unit` ( -- Used by confiscation, parisian_stock_sale and provincial_inspection
  `ID` INT(10) NOT NULL AUTO_INCREMENT,			/* !PK: numeric ID */
  `name` VARCHAR(50),							/* the name of the relevant unit in French */
  `definition` VARCHAR(250),					/* a definition of the relevant unit in English */
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;
INSERT INTO
  `unit`
VALUES
  (1, "balle", "bundle"),
  (2, "ballot", "crate"),
  (3, "copie", "copy"),
  (4, "panier", "basket"),
  (5, "paquet", "packet"),
  (6, "planches", "plates"),
  (7, "portefeuille", NULL),
  (8, "privilege", "the legal privilege to print the work"),
  (9, "vols separés", "seperate volumes (unquantified)"),
  (10, "mixed", "multiple units were used");
  
CREATE TABLE IF NOT EXISTS `confiscation_reason` ( -- Currently only used by confiscation
  `ID` INT(10) NOT NULL AUTO_INCREMENT,			/* !PK: numeric ID */
  `name` VARCHAR(100),							/* the name of the reason in French */
  `definition` VARCHAR(750),					/* a definition of the reason in English */
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;
INSERT INTO
  `confiscation_reason`
VALUES
  (1, "Contrefait", "The edition was counterfeit."),
  (2, "Nouveauté", "The edition was a 'novelty' unknown to the authorities."),
  (3, "Prohibé", "The edition was prohibited."),
  (4, "Comme venant en nombre à un particulier", "A particular person received a suspicious quanitity of the edition."),
  (5, "A mauvaise addresse", "The consignment had a suspcious address."),
  (6, "Fausse permission", "The permission for this consignment was false or forged."),
  (7, "Faute de renouvellement de privilege", "The privilege to sell this edition had lapsed."),
  (8, "En attendant ordre du magistrate", "The books were turned over to a magistrate for decision."),
  (9, "Indécent", "The books were indecent."),
  (10, "Scandaleux", "The books were scandalous or libellous."),
  (11, "Une autre", "Some other reason was given."),
  (12, "Inconnue", "Reason unknown.");

CREATE TABLE IF NOT EXISTS `judgment` ( -- Currently used by confiscation, condemnation and provincial_inspection 
  `ID` INT(10) NOT NULL AUTO_INCREMENT,			/* !PK: numeric ID */
  `name` VARCHAR(100),							/* the name of the decision in French */
  `definition` VARCHAR(750),					/* a definition of the decision in English */
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;
INSERT INTO
  `judgment`
VALUES
  (1, "Condamné au pilon", "The books were condemned to destruction."),
  (2, "Rayé de la liste des permissions tacites", "The books were removed from the list of tacitly permitted works."),
  (3, "Ajouté à la liste des permissions tacites", "The books were added to the list of tacitly permitted works."),
  (4, "Trouvé sur la liste des permissions tacites", "The books were found on the list of tacitly permitted works."),
  (5, "A rendre par ordre particulier", "The books were sent on under a particular order."),
  (6, "A rendre par ordre general", "The books were sent on under a general order."),
  (7, "A rendre au propriétaire du privilege", "The books were set to the owner of the privilege."),
  (8, "A attendre par jugemens du Permis", "The books were held, awaiting the judgement of the Permis."),
  (9, "Une autre", "Some other decision was made."),
  (10, "Inconnue", "Decision unknown.");
  
CREATE TABLE IF NOT EXISTS auction_role ( -- Currently only used for parisian_stock_auction
	`ID` INT NOT NULL,
	`role` VARCHAR(30),
	PRIMARY KEY(`ID`)
);
INSERT INTO auction_role
VALUES
	(1, "Syndic"),
	(2, "Adjoint"),
	(3, "Auctioneer");

CREATE TABLE IF NOT EXISTS auction_reason ( -- Currently only used by parisian_stock_auction
	`ID` INT NOT NULL,
	`reason` VARCHAR(30),
	PRIMARY KEY (`ID`)
);
INSERT INTO auction_reason
VALUES
	(1, "Bankruptcy"),
	(2, "Deceased Estate"),
	(3, "Not Given"),
	(4, "On Behalf of the King");
	
CREATE TABLE IF NOT EXISTS sale_type ( -- Currently only used by parisian_stock_sale
	`ID` INT NOT NULL AUTO_INCREMENT,
	`type` VARCHAR(50),
	PRIMARY KEY (`ID`)
);
INSERT INTO sale_type
VALUES
	(1, "Stock Sale"),
	(2, "Sale of Privilege");
	
CREATE TABLE IF NOT EXISTS transaction_direction( -- Currently only used by stn_transaction
	`ID` INT,
	`name` VARCHAR(5),
	PRIMARY KEY(`ID`)
);
INSERT INTO transaction_direction
VALUES
	(1,"In"),
	(2,"Out"),
	(3,"Neutral");

/*

## 3.2	The Regulation of the Book Trade

The Events recorded in these tables have to do with the regulation of the book
trade by the authorities. The authorities had two main interests: (1) censoring
illicit content; and (2) protecting (or not) booksellers' intellectual property.

These tables record data from six main sources:
-	The customs and confiscation registers: which editions were being shipped to Paris,
	and what did the censors make of them?
-	The Bastille Register: which confiscated editions were found in the Bastille
	during the Revolution?
-	The banned books list: which works appeared on the authorities' list of banned
	titles?
-	Provincial inspection registers: which books were being examined by the
	authorities in the provinces, and what did they do with them?
-	L'estampillage: which pirated editions were given the authorities' stamp of
	legitimacy during the 'estampillage' of the 1770s?
-	Condemnation registers: which books were condemned by various bookselling
	authorities across France?

*/

CREATE TABLE IF NOT EXISTS `consignment` ( -- From Excel spreadsheet
  `ID` INT(10) NOT NULL AUTO_INCREMENT,     	/* !PK: numeric ID (i.e. entry order) */
  `UUID` VARCHAR(60),							/* universal unique identifier */
  `confiscation_register_ms` INT(5),			/* MS number, either 21933 or 21934 */
  `confiscation_register_folio` VARCHAR(25),	/* folio reference in confiscation register */
  `customs_register_ms` INT(5),					/* MS number in the range 21914-26 */
  `customs_register_folio` VARCHAR(25),			/* folio reference in customs register */
  `ms_21935_folio` VARCHAR(25),					/* folio reference in MS21935, the supplementary confiscations register */
  `shipping_number` VARCHAR(25),				/* shipping number as given in the register */
  `marque` VARCHAR(25),							/* marque on consignment as given in the register */
  `inspection_date` DATE,						/* date recorded in the confiscation register */
  `origin_text` VARCHAR(250),					/* the origin of the consignment as recorded in the resgister */
  `origin_code` CHAR(5),						/* !FK: place_code of consingment origin */
  `customs_signatory_text` VARCHAR(250),		/* the name of the person who collected the residual books, as given in the register, including 'per' or 'on behalf of' etc */ 
  `customs_signatory` CHAR(6),					/* !FK: person_code of the person who collected the residual books */
  `handling_agent` CHAR(6),						/* !FK: the person_code of the addressee's agent, if they had one */
  `other_stakeholder` CHAR(6),					/* !FK: if the signatory signed on the behalf of someone other than the addressee, their person_code */
  `collectors` TEXT,							/* String listing all the confiscations register signatories */
  `acquit_a_caution` ENUM('yes','no'), 			/* did the consignment have an acquit a caution? */
  `confiscation_register_notes` TEXT,			/* notes arising from examination of the confiscation registers */
  `customs_register_notes` TEXT,				/* notes arising from examination of the customs registers */
  `all_collectors` TEXT,						/* string listing all persons who collected books from the consignment */
  `all_censors` TEXT,							/* string listing all censors who inspected books form the consignment */
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `consignment_addressee` (
	`ID` INT NOT NULL AUTO_INCREMENT,
	`consignment` INT, -- The ID of the consignment
	`person_code` CHAR(6), -- The ID of the owner/addressee
	`test` VARCHAR(255), -- The name as it appears in the register
	PRIMARY KEY (`ID`)
);

CREATE TABLE IF NOT EXISTS `confiscation` ( -- No data as yet
  `ID` INT(10) NOT NULL AUTO_INCREMENT,     	/* !PK: numeric ID (i.e. entry order) */
  `UUID` VARCHAR(60),							/* universal unique identifier */
  `consignment` INT(10) NOT NULL,				/* !FK: ID of the consignment the book was in */
  `title` VARCHAR(750),							/* the book title as it appears in the register */
  `book_number` CHAR(6),						/* !FK: book_number of the book */
  `number` INT(10),								/* number of units confiscated */
  `unit` INT(10),								/* !FK: ID of the relevant units */
  `confiscation_reason` INT(10),				/* !FK: ID of the relevant confiscation_reason */
  `other_reason` VARCHAR(255),					/* If 'une autre' is selected */
  `judgment` INT(10),							/* !FK: ID of the relevant judgment */
  `other_judgment` VARCHAR(255),				/* If 'une autre' is selected */
  `date` DATE,									/* the date the confiscation occurred (i.e. date that the decision was recorded) */
  `censor_name` VARCHAR(255),					/* the name of the censor as it appears in the register */
  `censor` CHAR(6),								/* !FK: person_code of the censor */
  `signatory_text` VARCHAR(255),				/* if the books were 'rendered' to someone, their name as it appears in the register */
  `signatory` CHAR(6),							/* !FK: person_code of signatory */
  `signatory_signed_on_behalf_of` CHAR(6),		/* !FK: person_code of whomever the signatory represented */
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `stamping` ( -- From manuscript_events
	`ID` INT NOT NULL AUTO_INCREMENT, -- PK [ID]
	`stamped_edition` CHAR(12) NOT NULL, -- Which edition was stamped? [ID_EditionName] (edition_code)
	`permitted_dealer` CHAR(6) NOT NULL, -- Who received the permission to sell? [ID_DealerName] (person_code)
	`attending_inspector` CHAR(6), -- Who was the inspector responsible? [ID_AgentA] (person_code)
	`attending_adjoint` CHAR(6), -- Who was the attending adjoint? [ID_AgentB] (person_code)
	`stamped_at_place` CHAR(5), -- Where was the edition stamped? [ID_PlaceName] (place_code)
	`stamped_at_location_type` VARCHAR(50), -- [EventLocation]
	`copies_stamped` INT, -- [EventCopies]
	`volumes_stamped` INT, -- Only one event has data in this field [EventVols]
	`date` DATE, -- When was it stamped? [EventDate]
	`ms_number` VARCHAR(50), -- Which MS was the stamping recorded in? [ID_Archive]
	`folio` VARCHAR(50), -- On which folio of the MS is the citation? [EventFolioPage]
	`citation` TEXT, -- The full citation in the MS [EventCitation]
	`page_stamped` VARCHAR(255), -- which page was stamped? [EventPageStamped]
	`edition_notes` TEXT, -- [EventNotes]
	`event_notes` TEXT, -- [EventOther]
	`article` VARCHAR(255), -- The article number [EventArticle]
	`date_entered` VARCHAR(255), -- [EventDateEntered]
	`entered_by_user` VARCHAR(255), -- [EventUser]
	PRIMARY KEY (`ID`)
);

CREATE TABLE IF NOT EXISTS `banned_list_record` ( -- From manuscript_titles_illegal
	`ID` INT NOT NULL AUTO_INCREMENT,
	`UUID` CHAR(36),
	`work_code` CHAR(12),
	`title` VARCHAR(750),
	`author` VARCHAR(255),
	`date` DATE, -- Need to remove 'No date available'
	`folio` VARCHAR(50),
	`notes` TEXT,
	PRIMARY KEY(`ID`)
);

CREATE TABLE IF NOT EXISTS `bastille_register_record` ( -- From manuscript_titles_illegal
	`ID` INT NOT NULL AUTO_INCREMENT,
	`UUID` CHAR(36),
	`edition_code` CHAR(12),
	`work_code` CHAR(12), -- To be deleted once data is fully resolved
	`title` VARCHAR(750),
	`author_name` VARCHAR(750),
	`imprint` VARCHAR(750),
	`publication_year` INT, -- Need to remove 'No date available'
	`copies_found` VARCHAR(255),
	`current_volumes` VARCHAR(255),
	`total_volumes` VARCHAR(255),
	`category` VARCHAR(255),
	`notes` TEXT,
	PRIMARY KEY(`ID`)
);
	
CREATE TABLE IF NOT EXISTS `condemnation` (
	`ID` INT NOT NULL AUTO_INCREMENT,
	`title` VARCHAR(1000),
	`work_code` CHAR(12), -- !FK: work.work_code
	`edition_notes` CHAR(12),
	`insitution` INT, -- !FK: corporate_entity.entity_code
	`date` DATE,
	`judgment` INT, -- !FK: judgment.ID
	`other_judgment` VARCHAR(255),
	`notes` TEXT,
	PRIMARY KEY (`ID`)
);

CREATE TABLE IF NOT EXISTS `provincial_inspection` ( -- from Excel spreadsheet
	`ID` INT NOT NULL AUTO_INCREMENT,
	`date` DATE,
	`inspected_in` CHAR(5), -- !FK: place.place_code
	`title` VARCHAR(1000),
	`work_code` CHAR(12), -- !FK: work.work_code
	`author` VARCHAR(1000),
	`origin` CHAR(5), -- !FK: place.place_code
	`number_inspected` INT,
	`units` INT, -- !FK: unit.ID
	`aquit_a_caution` BIT,
	`judgment` INT, -- !FK: judgment.ID
	`other_judgment` VARCHAR(255),
	`judgment_date` DATE,
	`tracking_number` VARCHAR(255),
	`folio` VARCHAR(255),
	`item_number` INT,
	PRIMARY KEY(`ID`)
);

CREATE TABLE IF NOT EXISTS `permission_simple_grant` ( -- from Excel spreadsheet
	`ID` INT NOT NULL AUTO_INCREMENT,
	`dawson_number` INT,
	`edition_code` CHAR(12), -- !FK: edition.edition_code
	`stated_publisher` VARCHAR(255),
	`stated_publisher_profession` VARCHAR(255),
	`publisher_person_code` CHAR(6), -- !FK: person.person_code
	`publisher_entity_code` INT, -- !FK: corporate_entity.entity_code
	`stated_place_of_publication` VARCHAR(255),
	`actual_place_of_publication` CHAR(5), -- !FK: place.place_code
	`date_granted` DATE,
	`notes` TEXT,
	PRIMARY KEY (`ID`)
);

/*

## 3.3	The Production and Exchange of Books (1):
		The Parisian Stock Sales

The Parisian Stock Sales were large auctions at which booksellers' stock was sold
off en masse. The registers record exactly who each lot was sold to, and for
how much.

*/

CREATE TABLE IF NOT EXISTS `parisian_stock_auction` ( -- From manuscript_sales_events
	`auction_id` CHAR(5), -- PK
	`ms_number` INT, -- The MS number where the auction is recorded
	`previous_owner` CHAR(6), -- The person whose books are being sold (person_code)
	`auction_reason` INT,
	`place` CHAR(5), -- place auction took place (always pl306)
	PRIMARY KEY (`auction_id`)
);

CREATE TABLE IF NOT EXISTS `auction_administrator` (
	`auction_id` CHAR(5) NOT NULL, -- ID of the auction
	`administrator_id` CHAR(6) NOT NULL, -- ID of the administrator
	`administrator_role` INT NOT NULL,
	PRIMARY KEY (`auction_id`, `administrator_id`)
);

CREATE TABLE IF NOT EXISTS `parisian_stock_sale` ( -- From manuscript_events_sales
	`ID` INT NOT NULL AUTO_INCREMENT,
	`auction_id` CHAR(5) NOT NULL, -- At which auction did this take place? [ID_SaleAgent]
	`purchaser` CHAR(6), -- person_code, [ID_DealerName]
	`purchased_edition` CHAR(12), -- edition_code [ID_EditionName]
	`sale_type` INT,
	`units_sold` VARCHAR(50),
	`units` INT,
	`volumes_traded` VARCHAR(50),
	`lot_price` VARCHAR(50),
	`date` DATE,
	`folio` VARCHAR(50),
	`citation` VARCHAR(255), -- Full citation in the original source
	`article_number` INT,
	`edition_notes` TEXT, -- [EventNotes]
	`event_notes` TEXT, -- [EventOther]
	`sale_notes` TEXT, -- [EventMoreNotes]
	PRIMARY KEY (`ID`)
);

/*

## 3.4	The Production and Exchange of Books (2):
		The Société Typographique de Neuchâtel

This is the core data of the original FBTEE database. The STN was a major publisher
based in Switzerland. Their ledgers record not only which books they bought and
sold, but also which books they printed, how many copies they had lying in the
warehouse, and which titles were gifted to or returned by their clients.

*/

CREATE TABLE IF NOT EXISTS `stn_order` ( -- From orders
	`order_code` CHAR(9) NOT NULL,
	`client_code` CHAR(6),
	`place_code` CHAR(5),
	`date` DATE,
	`manuscript_number` VARCHAR(50),
	`manuscript_type` VARCHAR(50),
	`balle_number` VARCHAR(50),
	`cash` BIT,
	PRIMARY KEY(`order_code`)
);

CREATE TABLE IF NOT EXISTS `stn_order_agent` ( -- From orders_agents
	`order_code` CHAR(9) NOT NULL,
	`client_code` CHAR(6) NOT NULL,
	`place_code` CHAR(5),
	PRIMARY KEY(`order_code`, `client_code`)
);

CREATE TABLE IF NOT EXISTS `stn_order_sent_via` ( -- From orders_sent_via
	`order_code` CHAR(9) NOT NULL,
	`client_code` CHAR(6) NOT NULL,
	`place_code` CHAR(5),
	PRIMARY KEY(`order_code`, `client_code`)
);

CREATE TABLE IF NOT EXISTS `stn_order_sent_via_place` ( -- From orders_sent_via_place
	`order_code` CHAR(9) NOT NULL,
	`place_code` CHAR(5) NOT NULL,
	PRIMARY KEY(`order_code`, `place_code`)
);

CREATE TABLE IF NOT EXISTS `stn_transaction` ( -- From transactions
	`transaction_code` CHAR(9) NOT NULL,
	`order_code` CHAR(9) NOT NULL,
	`page_or_folio_numbers` VARCHAR(50),
	`account_heading` VARCHAR(50),
	`direction` INT, -- !FK: refers to transaction_direction (new field)
	`transaction_description` VARCHAR(50), -- Old direction_of_transaction field
	`work_code` CHAR(12), -- Old super_book_code field [this should be deleted. There are three rows in the original data without edition codes]
	`edition_code` CHAR(12), -- Old book_code field
	`stn_abbreviated_title` VARCHAR(600),
	`total_number_of_volumes` INT,
	`notes` VARCHAR(4000),
	PRIMARY KEY(`transaction_code`, `order_code`) -- Not sure why the composite index
);

CREATE TABLE IF NOT EXISTS `stn_transaction_volumes_exchanged` ( -- From transactions_volumes_exchanged
	`transaction_code` CHAR(9) NOT NULL,
	`order_code` CHAR(9) NOT NULL,
	`volume_number` INT NOT NULL,
	`number_of_copies` INT,
	PRIMARY KEY(`transaction_code`, `order_code`, `volume_number`)
);

/*

# SECTION 4: MMF-2

The MMF-2 database is a new digital edition of 'Bibliographie du genre romanesque
français, 1700-1800' (Martin, Myle and Frautschi). It aims to provide a complete
bibliographic record of every novel published in French during the eighteenth
century. It records key data about the content, publication and authorship of
each edition of each work, and in addition records library holdings and later
references for each one.

This project is discrete, but each edition will be replicated in the main
work and edition tables of the MPCE database, and linked accordingly.

In an ideal world, updates to the MMF data would automatically trickle through
to the MPCE databse, but to implement this may be outside the project's current
scope.

*/

CREATE TABLE IF NOT EXISTS mmf_work (
	work_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	uuid CHAR(36) NOT NULL,
	work_identifier CHAR(12),
	translation VARCHAR(128),
	title TEXT,
	comments TEXT,
	bur_references TEXT,
	bur_comments TEXT,
	original_title TEXT,
	translation_comments TEXT,
	description TEXT
);
CREATE TABLE IF NOT EXISTS mmf_edition (
	edition_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	work_id INT,
	uuid CHAR(36) NOT NULL,
	work_identifier CHAR(12),
	ed_identifer CHAR(12),
	edition_counter CHAR(7),
	translation VARCHAR(128),
	author VARCHAR(255),
	translator VARCHAR(255),
	short_title VARCHAR(255),
	long_title TEXT,
	collection_title TEXT,
	publication_details TEXT,
	comments TEXT,
	final_comments TEXT,
	first_text TEXT,
	mpce_edition_code CHAR(12) -- Link to MPCE database
);

CREATE TABLE IF NOT EXISTS mmf_holding (
	holding_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	edition_id INT NOT NULL,
	lib_name VARCHAR(255),
	lib_id INT
);

CREATE TABLE IF NOT EXISTS mmf_lib (
	lib_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	short_name VARCHAR(255),
	full_name TEXT
);

CREATE TABLE IF NOT EXISTS mmf_ref (
	ref_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	work_id INT NOT NULL,
	short_name VARCHAR(255),
	page_num INT,
	ref_work INT,
	ref_type INT NOT NULL
);

CREATE TABLE IF NOT EXISTS mmf_ref_type (
	ref_type_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	name VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS mmf_error (
	error_id INT AUTO_INCREMENT PRIMARY KEY,
	filename VARCHAR(255),
	edition_id INT,
	work_id INT,
	text TEXT,
	error_note VARCHAR(255),
	date DATE
);