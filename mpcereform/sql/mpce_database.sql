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

CREATE TABLE IF NOT EXISTS `work` ( -- From manuscript_books [super_books in original STN db]
	/*
	This is the new version of the `super_books` table. Both the table and the key
	column have been renamed 'work'.
	In the transition to the new database in c. 2016, the data type was changed.
	Originally, the super_book_code was a string of fixed length 11. It was
	lengthened to 12.
	*/
	`work_code` CHAR(12) NOT NULL,
	`work_title` VARCHAR(750) NOT NULL,
	`parisian_keyword` VARCHAR(2000),
	`illegality_notes` VARCHAR(2000),
	`categorisation_fuzzy_value` INT DEFAULT 0,
	`categorisation_notes` TEXT,
	PRIMARY KEY (`work_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `edition` ( -- From manuscript_books_editions [books in original STN db]
	/*
	This is the new version of the `books` table. It has been renamed `edition`.
	The data type of `edition_code` is now CHAR(12), a change from CHAR(9) in the
	original STN database.
	*/
	`edition_code` CHAR(12) NOT NULL DEFAULT 'new',
	`work_code` CHAR(12),
	`edition_status` VARCHAR(255),
	`edition_type` VARCHAR(255),
	`full_book_title` VARCHAR(750),
	`short_book_titles` VARCHAR(1000),
	`translated_title` VARCHAR(750),
	`translated_language` VARCHAR(255),
	`languages` VARCHAR(200),
	`imprint_publishers` VARCHAR(1000),
	`actual_publishers` VARCHAR(1000),
	`imprint_publication_places` VARCHAR(1000),
	`actual_publication_places` VARCHAR(1000),
	`imprint_publication_years` VARCHAR(1000),
	`actual_publication_years` VARCHAR(255),
	`pages` VARCHAR(1000),
	`quick_pages` VARCHAR(255),
	`number_of_volumes` INT(11),
	`section` VARCHAR(255),
	`edition` VARCHAR(255),
	`book_sheets` VARCHAR(255),
	`known_pirated` BIT DEFAULT 0,
	`notes` TEXT,
	`research_notes` VARCHAR(1000),
	`url` VARCHAR(1000),
	PRIMARY KEY (`edition_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Book classification tables

CREATE TABLE IF NOT EXISTS parisian_category (
	`parisian_category_code` CHAR(5) NOT NULL,
	`name` VARCHAR(255) NOT NULL,
	`ancestor1` CHAR(5),
	`ancestor2` CHAR(5),
	`ancestor3` CHAR(5),
	PRIMARY KEY (`parisian_category_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS keyword (
	`keyword_code` CHAR(5) NOT NULL,
	`keyword` VARCHAR(250),
	`definition` VARCHAR(1000),
	`tag_code` CHAR(3),
	PRIMARY KEY (`keyword_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS keyword_fuzzy_values (
	`fuzzy_value_code` INT NOT NULL,
	`fuzzy_value` VARCHAR(255),
	PRIMARY KEY (`fuzzy_value_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS work_keyword (
	`ID` INT AUTO_INCREMENT,
	`work_code` CHAR(12),
	`keyword_code` CHAR(5), 
	PRIMARY KEY (`ID`),
	UNIQUE INDEX(`work_code`,`keyword_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*
Unfortunately these two association tables were created using the keyword
names, rather than the keyword codes... This will need to be transformed.
*/
CREATE TABLE IF NOT EXISTS keyword_free_association (
	`ID` INT AUTO_INCREMENT,
	`keyword_1` CHAR(5),
	`keyword_2` CHAR(5),
	PRIMARY KEY (`ID`),
	UNIQUE INDEX(`keyword_1`,`keyword_2`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS keyword_tree_association (
	`ID` INT AUTO_INCREMENT,
	`keyword_1` CHAR(5),
	`keyword_2` CHAR(5),
	PRIMARY KEY (`ID`),
	UNIQUE INDEX(`keyword_1`,`keyword_2`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*

## 2.2	Agents

Agents have posed difficult problems in the development of the FBTEE database.
In the original STN database, a distinction was made between 'clients', which could
be people or organisations, and 'people', who could only be natural persons.
Moreover, the 'clients' table of the original STN database recorded lots of
information about how a particular client was related to the STN.

As the project expanded, numerous seperate tables of persons were created. In
addition, new agents were assigned new client_codes as a matter of course, rather
than agent_codes. No decision was made about how to treat organisations that
were not clients of the STN.

In this schema, a thorough revamp is proposed. The 'clients' table will be frozen
in its original form, meaning the production database will contain a discrete list
of all clients of the STN. The person table (renamed from the original 'people'
table) will be updated to include the details of every person we have encountered
in our datasets. A new corporate_entity table will be created to store information
about partnerships, government agencies etc.

*/

CREATE TABLE IF NOT EXISTS `agent` ( -- From `people`
	`agent_code` CHAR(8) NOT NULL,	-- Former 'person_code'
	`name` VARCHAR(255),
	`sex` CHAR(1),					-- Gender of person, or of members if known
	`title` VARCHAR(255),
	`other_names` VARCHAR(1023),
	`designation` VARCHAR(255),
	`status` VARCHAR(255),
	`start_date` VARCHAR(255),		-- Birth date, earliest fl. date or foundation date as appropriate
	`end_date` VARCHAR(255),		-- Death date, latest fl. date or winding-up date as appropriate
	`notes` TEXT,
	`cerl_id` CHAR(11),
	`corporate_entity` BIT(1),		-- Is this agent a corporate entity? y/n/NULL
	PRIMARY KEY (`agent_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `is_member_of` ( -- New table
	`ID` INT AUTO_INCREMENT,
	`member` CHAR(8) NOT NULL,				-- agent_code of the member
	`corporate_entity` CHAR(8) NOT NULL,	-- agent_code of the agent they are a member of
	PRIMARY KEY (`ID`),
	UNIQUE INDEX(`member`,`corporate_entity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Other types of person, and additional metadata

CREATE TABLE IF NOT EXISTS `stn_client` ( -- From clients
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
	`notes` TEXT,
	PRIMARY KEY (`client_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `stn_client_agent` ( -- From clients_people
	`ID` INT AUTO_INCREMENT,
	`client_code` CHAR(6) NOT NULL,
	`agent_code` CHAR(8) NOT NULL,
	PRIMARY KEY (`ID`),
	UNIQUE INDEX(`client_code`, `agent_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `stn_client_profession` ( -- From clients_professions
	`ID` INT AUTO_INCREMENT,
	`client_code` CHAR(6) NOT NULL,
	`profession_code` CHAR(6) NOT NULL,
	PRIMARY KEY(`ID`),
	UNIQUE INDEX(`client_code`, `profession_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `profession` ( -- From professions
	`profession_code` CHAR(5) NOT NULL,
	`profession_type` VARCHAR(50),
	`translated_profession` VARCHAR(100),
	`profession_group` VARCHAR(100),
	`economic_sector` VARCHAR(100),
	PRIMARY KEY(`profession_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `agent_profession` ( -- From people_professions
	`ID` INT AUTO_INCREMENT,
	`agent_code` CHAR(8) NOT NULL,
	`profession_code` CHAR(5) NOT NULL,
	PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `edition_author` ( -- From manuscript_books_authors
	`ID` INT AUTO_INCREMENT,
	`edition_code` CHAR(12) NOT NULL,
	`author` CHAR(8) NOT NULL, -- Person code of the author
	`author_type` int NOT NULL,
	`certain` INT,
	PRIMARY KEY(`ID`),
	UNIQUE INDEX(`edition_code`,`author`,`author_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `author_type` ( -- New table
	`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	`type` VARCHAR(20),
	`definition` TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
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

CREATE TABLE IF NOT EXISTS `place` ( -- From manuscript_places
	`place_code` CHAR(5) NOT NULL,
	`name` VARCHAR(255),
	`alternative_names` VARCHAR(255),
	`town` VARCHAR(255),
	`C18_lower_territory` VARCHAR(255),
	`C18_sovereign_territory` VARCHAR(255),
	`C21_admin` VARCHAR(255),
	`C21_country` VARCHAR(255),
	`geographic_zone` VARCHAR(255),
	`BSR` VARCHAR(255),
	`HRE` BIT(1),
	`EL` BIT(1),
	`IFC` BIT(1),
	`P` BIT(1),
	`HE` BIT(1),
	`HT` BIT(1),
	`WT` BIT(1),
	`PT` BIT(1),
	`PrT` BIT(1),
	`distance_from_neuchatel` DOUBLE,
	`latitude` DECIMAL(10,8),
	`longitude` DECIMAL(10,8),
	`geoname` INT(11),
	`notes` TEXT,
	PRIMARY KEY (`place_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `agent_address` ( -- From clients_addresses
	`id` int NOT NULL AUTO_INCREMENT PRIMARY KEY,
	`agent_code` CHAR(8) NOT NULL,
	`place_code` CHAR(5) NOT NULL,
	`address` VARCHAR(50),
	`from_date` VARCHAR(255), -- To be validated at another time
	`to_date` VARCHAR(255) -- To be validated at another time
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

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
	`ID` INT AUTO_INCREMENT,
	`edition_code` CHAR(9) NOT NULL, -- Formerly book_code
	`call_number` VARCHAR(255) NOT NULL,
	PRIMARY KEY (`ID`),
	UNIQUE INDEX(`edition_code`, `call_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `stn_edition_catalogue` ( -- From books_stn_catalogues
	`ID` INT AUTO_INCREMENT,
	`edition_code` CHAR(9) NOT NULL, -- Formerly book_code
	`catalogue` VARCHAR(255) NOT NULL,
	PRIMARY KEY (`ID`),
	UNIQUE INDEX(`edition_code`, `catalogue`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `stn_client_correspondence_ms` ( -- From clients_correspondence_manuscripts
	`ID` INT AUTO_INCREMENT,
	`client_code` CHAR(6) NOT NULL,
	`position` INT NOT NULL,
	`manuscript_numbers` VARCHAR(500),
	PRIMARY KEY (`ID`),
	UNIQUE INDEX(`client_code`,`position`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `stn_client_correspondence_place` ( -- From clients_correspondence_places
	`ID` INT AUTO_INCREMENT,
	`client_code` CHAR(6) NOT NULL,
	`place_code` CHAR(5) NOT NULL,
	`from_date` VARCHAR(255), -- To be validated at another time
	PRIMARY KEY(`ID`),
	UNIQUE INDEX(`client_code`,`place_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

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
  `name` VARCHAR(255),							/* the name of the relevant unit in French */
  `definition` VARCHAR(255),					/* a definition of the relevant unit in English */
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
  `name` VARCHAR(255),							/* the name of the reason in French */
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
  `name` VARCHAR(255),							/* the name of the decision in French */
  `definition` VARCHAR(750),					/* a definition of the decision in English */
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;
INSERT INTO
  `judgment`
VALUES
  (1, "Condamné au pilon", "to be condemned the pulping room in the Bastille."),
  (2, "Rayé de la liste des permissions tacites", "to be struck from the list of tacitly permitted works."),
  (3, "Ajouté à la liste des permissions tacites", "to be added to the list of tacitly permitted works."),
  (4, "Trouvé sur la liste des permissions tacites", "(The books were already) on the list of tacitly permitted works."),
  (5, "A rendre par ordre particulier", "to be returned by an order specific to this case."),
  (6, "A rendre par ordre general", "to be returned under a general order."),
  (7, "A rendre au propriétaire du privilege", "to be sent to the owner of the privilege."),
  (8, "A attendre par jugemens du Permis", "to await the judgement concerning the permit."),
  (9, "A rendre à la librairie", "to be sent to the Bureau de la Librairie (the government Office charged with policing the book trade)."),
  (10, "A renvoyer au libraire étranger par ordre", "to be returned to the foreign-based bookseller [who sent them]."),
  (11, "A renvoyer au libraire chargé de la distribution", "to be returned to the bookseller entrusted with their distribution."),
  (12, "Inconnue", "Decision unknown."),
  (13, "Une autre", "Some other decision was made.");
  
CREATE TABLE IF NOT EXISTS auction_role ( -- Currently only used for parisian_stock_auction
	`ID` INT NOT NULL,
	`role` VARCHAR(30),
	PRIMARY KEY(`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
INSERT INTO auction_role
VALUES
	(1, "Syndic"),
	(2, "Adjoint"),
	(3, "Auctioneer");

CREATE TABLE IF NOT EXISTS auction_reason ( -- Currently only used by parisian_stock_auction
	`ID` INT NOT NULL,
	`reason` VARCHAR(30),
	PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
INSERT INTO sale_type
VALUES
	(1, "Stock Sale"),
	(2, "Sale of Privilege");
	
CREATE TABLE IF NOT EXISTS transaction_direction( -- Currently only used by stn_transaction
	`ID` INT,
	`name` VARCHAR(255),
	PRIMARY KEY(`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
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
  `UUID` VARCHAR(255),							/* universal unique identifier */
  `confiscation_register_ms` INT(5),			/* MS number, either 21933 or 21934 */
  `confiscation_register_folio` VARCHAR(255),	/* folio reference in confiscation register */
  `customs_register_ms` INT(255),				/* MS number in the range 21914-26 */
  `customs_register_folio` VARCHAR(255),		/* folio reference in customs register */
  `ms_21935_folio` VARCHAR(255),				/* folio reference in MS21935, the supplementary confiscations register */
  `ms_21935_entry_no` VARCHAR(255),				/* entry number in MS21935 */
  `shipping_number` VARCHAR(255),				/* shipping number as given in the register */
  `marque` VARCHAR(255),						/* marque on consignment as given in the register */
  `inspection_date` DATE,						/* date recorded in the confiscation register */
  `origin_text` VARCHAR(255),					/* the origin of the consignment as recorded in the resgister */
  `origin_code` CHAR(5),						/* !FK: place_code of consingment origin */
  `other_stakeholder` CHAR(8),					/* !FK: agent_code of the other stakeholder, if there is one */
  `returned_to_name` VARCHAR(255),				/* Name of the person the consignment was returned to, as it appears in the register */
  `returned_to_agent` CHAR(8),					/* !FK: The person to whom the consignment was returned */
  `returned_to_town` VARCHAR(255),				/* Name of the place the consignment went back to */
  `returned_to_place` CHAR(5),					/* !FK: The place the consignment went back to */
  `acquit_a_caution` ENUM('yes','no'), 			/* did the consignment have an acquit a caution? */
  `notes` TEXT,									/* Research notes on the event */
  `all_collectors` TEXT,						/* string listing all persons who collected books from the consignment */
  `all_censors` TEXT,							/* string listing all censors who inspected books form the consignment */
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `consignment_addressee` ( -- New table: owners/addressees of the consignment
	`ID` INT NOT NULL AUTO_INCREMENT,
	`consignment` INT, -- The ID of the consignment
	`agent_code` CHAR(8), -- The ID of the owner/addressee
	`text` VARCHAR(255), -- The name as it appears in the register
	PRIMARY KEY (`ID`),
	UNIQUE INDEX(`consignment`, `agent_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `consignment_signatory` ( -- New table: persons who sign the customs register
	`ID` INT NOT NULL AUTO_INCREMENT,
	`consignment` INT, -- The ID of the consignment
	`agent_code` CHAR(8), -- The ID of the customs register signatory
	`text` VARCHAR(255), -- The name as it appears in the register
	PRIMARY KEY (`ID`),
	UNIQUE INDEX(`consignment`, `agent_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `consignment_handling_agent` ( -- New table: handling agents of the consignment
	`ID` INT NOT NULL AUTO_INCREMENT,
	`consignment` INT, -- The ID of the consignment
	`agent_code` CHAR(8), -- The ID of the handling agent
	`text` VARCHAR(255), -- The name as it appears in the register
	PRIMARY KEY (`ID`),
	UNIQUE INDEX(`consignment`, `agent_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `confiscation` ( -- No data as yet
  `ID` INT(10) NOT NULL AUTO_INCREMENT,     	/* !PK: numeric ID (i.e. entry order) */
  `UUID` VARCHAR(60),							/* universal unique identifier */
  `consignment` INT(10) NOT NULL,				/* !FK: ID of the consignment the book was in */
  `title` VARCHAR(750),							/* the book title as it appears in the register */
  `edition_code` CHAR(12),						/* !FK: edition_code of the book */
  `number` INT(10),								/* number of units confiscated */
  `unit` INT(10),								/* !FK: ID of the relevant units */
  `binding` VARCHAR(255),						/* How the edition was bound */
  `confiscation_reason` INT(10),				/* !FK: ID of the relevant confiscation_reason */
  `other_reason` VARCHAR(255),					/* If 'une autre' is selected */
  `judgment` INT(10),							/* !FK: ID of the relevant judgment */
  `other_judgment` VARCHAR(255),				/* If 'une autre' is selected */
  `date` DATE,									/* the date the confiscation occurred (i.e. date that the decision was recorded) */
  `censor_name` VARCHAR(255),					/* the name of the censor as it appears in the register */
  `censor` CHAR(8),								/* !FK: agent_code of the censor */
  `signatory_text` VARCHAR(255),				/* if the books were 'rendered' to someone, their name as it appears in the register */
  `signatory` CHAR(8),							/* !FK: agent_code of signatory */
  `signatory_signed_on_behalf_of` CHAR(8),		/* !FK: agent_code of whomever the signatory represented */
  `notes` TEXT,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `stamping` ( -- From manuscript_events
	`ID` INT NOT NULL AUTO_INCREMENT, -- PK [ID]
	`stamped_edition` CHAR(12) NOT NULL, -- Which edition was stamped? [ID_EditionName] (edition_code)
	`permitted_dealer` CHAR(9), -- Who received the permission to sell? [ID_DealerName] (agent_code)
	`attending_inspector` CHAR(9), -- Who was the inspector responsible? [ID_AgentA] (agent_code)
	`attending_adjoint` CHAR(9), -- Who was the attending adjoint? [ID_AgentB] (agent_code)
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `bastille_register_record` ( -- From manuscript_titles_illegal
	`ID` INT NOT NULL AUTO_INCREMENT,
	`UUID` CHAR(36),
	`edition_code` CHAR(12),
	`work_code` CHAR(12), -- To be deleted once data is fully resolved
	`title` VARCHAR(750),
	`author_name` VARCHAR(750),
	`imprint` TEXT,
	`publication_year` DATE, -- Need to remove 'No date available'
	`copies_found` VARCHAR(255),
	`current_volumes` VARCHAR(255),
	`total_volumes` VARCHAR(255),
	`category` VARCHAR(255),
	`notes` TEXT,
	PRIMARY KEY(`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	
CREATE TABLE IF NOT EXISTS `condemnation` (
	`ID` INT NOT NULL AUTO_INCREMENT,
	`folio` VARCHAR(255),
	`title` VARCHAR(1000),
	`work_code` CHAR(12), -- !FK: work.work_code
	`edition_notes` CHAR(12),
	`institution_text` VARCHAR(255),
	`insitution` CHAR(8), -- !FK: agent_code
	`date` DATE,
	`judgment` INT, -- !FK: judgment.ID
	`other_judgment` VARCHAR(255),
	`notes` TEXT,
	PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `provincial_inspection` ( -- from Excel spreadsheet
	`ID` INT NOT NULL AUTO_INCREMENT,
	`ms_ref` VARCHAR(255),
	`folio` VARCHAR(255),
	`edition_code` CHAR(12), -- !FK: code of the inspected edition
	`work_code` CHAR(12), -- !FK: work_code if edition_code unavailable
	`inspected_in` CHAR(5), -- !FK: code of the inspected edition
	`item` INT,
	`inspected_on` DATE,
	`ballot` VARCHAR(255),
	`consignment` VARCHAR(255),
	`acquit_a_caution` VARCHAR(255),
	`origin` CHAR(5), -- !FK: code of the inspected edition
	`author` TEXT,
	`title` TEXT,
	`imprint_place` TEXT,
	`imprint_publisher` TEXT,
	`imprint_date` CHAR(4),
	`volumes` VARCHAR(255),
	`format` VARCHAR(255),
	`languages` VARCHAR(255),
	`addressee` VARCHAR(255),
	`num_copies` INT,
	`inspected_by` TEXT,
	`decision` VARCHAR(255),
	`decision_date` DATE,
	`notes` TEXT,
	PRIMARY KEY(`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `permission_simple_grant` ( -- from Excel spreadsheet
	`ID` INT NOT NULL AUTO_INCREMENT,
	`dawson_work` INT,
	`dawson_edition` INT,
	`date_granted` DATE,
	`edition_code` CHAR(12),
	`licensee` CHAR(8),
	`licensed_copies` INT,
	`printed_copies_estimate` INT,
	`work_confirmed` ENUM('yes', 'no', 'probable'),
	`edition_confirmed` ENUM('yes', 'no', 'probable'),
	PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

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
	`previous_owner` CHAR(8), -- The person whose books are being sold (agent_code)
	`auction_reason` INT,
	`place` CHAR(5), -- place auction took place (always pl306)
	PRIMARY KEY (`auction_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `auction_administrator` (
	`auction_id` CHAR(5) NOT NULL, -- ID of the auction
	`administrator_id` CHAR(8) NOT NULL, -- agent_code of the administrator
	`administrator_role` INT,
	PRIMARY KEY (`auction_id`, `administrator_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `parisian_stock_sale` ( -- From manuscript_events_sales
	`ID` INT NOT NULL AUTO_INCREMENT,
	`auction_id` CHAR(5) NOT NULL, -- At which auction did this take place? [ID_SaleAgent]
	`purchaser` CHAR(8), -- agent_code, [ID_DealerName]
	`purchased_edition` CHAR(12), -- edition_code [ID_EditionName]
	`sale_type` INT,
	`units_sold` VARCHAR(50),
	`units` INT,
	`volumes_traded` VARCHAR(50),
	`lot_price` VARCHAR(50),
	`date` DATE,
	`folio` VARCHAR(50),
	`citation` TEXT, -- Full citation in the original source
	`article_number` INT,
	`edition_notes` TEXT, -- [EventNotes]
	`event_notes` TEXT, -- [EventOther]
	`sale_notes` TEXT, -- [EventMoreNotes]
	PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*

## 3.4	The Production and Exchange of Books (2):
		The Société Typographique de Neuchâtel

This is the core data of the original FBTEE database. The STN was a major publisher
based in Switzerland. Their ledgers record not only which books they bought and
sold, but also which books they printed, how many copies they had lying in the
warehouse, and which titles were gifted to or returned by their clients.

In addition to the FBTEE-1 data, our database also includes data published and
made available to other scholars by Robert Darnton: http://www.robertdarnton.org/literarytour/booksellers
His data comprises a sample of orders from the books of several of the STN's clients.

*/

CREATE TABLE IF NOT EXISTS `stn_order` ( -- From orders
	`order_code` CHAR(9) NOT NULL,
	`client_code` CHAR(6),
	`place_code` CHAR(5),
	`date` VARCHAR(255),
	`manuscript_number` VARCHAR(50),
	`manuscript_type` VARCHAR(50),
	`balle_number` VARCHAR(50),
	`cash` BIT,
	PRIMARY KEY(`order_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `stn_order_agent` ( -- From orders_agents
	`ID` INT AUTO_INCREMENT,
	`order_code` CHAR(9) NOT NULL,
	`client_code` CHAR(6) NOT NULL,
	`place_code` CHAR(5),
	PRIMARY KEY(`ID`),
	UNIQUE INDEX(`order_code`,`client_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `stn_order_sent_via` ( -- From orders_sent_via
	`ID` INT AUTO_INCREMENT,
	`order_code` CHAR(9) NOT NULL,
	`client_code` CHAR(6) NOT NULL,
	`place_code` CHAR(5),
	PRIMARY KEY(`ID`),
	UNIQUE INDEX(`order_code`,`client_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `stn_order_sent_via_place` ( -- From orders_sent_via_place
	`ID` INT AUTO_INCREMENT,
	`order_code` CHAR(9) NOT NULL,
	`place_code` CHAR(5) NOT NULL,
	PRIMARY KEY(`ID`),
	UNIQUE INDEX(`order_code`,`place_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `stn_transaction` ( -- From transactions
	`ID` INT AUTO_INCREMENT,
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
	`notes` TEXT,
	PRIMARY KEY(`ID`),
	UNIQUE INDEX(`order_code`,`transaction_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `stn_transaction_volumes_exchanged` ( -- From transactions_volumes_exchanged
	`ID` INT AUTO_INCREMENT,
	`transaction_code` CHAR(9) NOT NULL,
	`order_code` CHAR(9) NOT NULL,
	`volume_number` INT NOT NULL,
	`number_of_copies` INT,
	PRIMARY KEY(`ID`),
	UNIQUE INDEX(`transaction_code`,`order_code`,`volume_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `stn_darnton_sample_order` ( -- From http://www.robertdarnton.org/sites/default/files/CommandesLibrairesfrancais.xls
	`ID` INT AUTO_INCREMENT PRIMARY KEY,		-- simple numeric ID
	`title` VARCHAR(255),						-- Darnton's short title
	`edition_code` CHAR(12),					-- edition code of ordered book
	`format` VARCHAR(255),						-- format of book
	`volumes` VARCHAR(255),						-- number of volumes
	`author` VARCHAR(255),						-- name of author
	`num_ordered` VARCHAR(255),					-- number ordered
	`date_ordered` DATE,						-- date order was placed
	`edition_long_title` TEXT,					-- long title of the book
	`ordered_by` CHAR(6),						-- !FK: client_code of STN client
	`notes` TEXT								-- Darnton's research notes
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

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

CREATE TABLE IF NOT EXISTS `mmf_work` (
	`work_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	`uuid` CHAR(36) NOT NULL,
	`work_identifier` CHAR(12),
	`translation` VARCHAR(128),
	`title` TEXT,
	`comments` TEXT,
	`bur_references` TEXT,
	`bur_comments` TEXT,
	`original_title` TEXT,
	`translation_comments` TEXT,
	`description` TEXT,
	`incipit` TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `mmf_edition` (
	`edition_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	`work_id` INT,
	`uuid` CHAR(36) NOT NULL,
	`work_identifier` CHAR(12),
	`ed_identifer` CHAR(12),
	`edition_counter` CHAR(7),
	`translation` VARCHAR(128),
	`author` VARCHAR(255),
	`translator` VARCHAR(255),
	`short_title` VARCHAR(255),
	`long_title` TEXT,
	`collection_title` TEXT,
	`publication_details` TEXT,
	`comments` TEXT,
	`final_comments` TEXT,
	`mpce_edition_code` CHAR(12) -- Link to MPCE database
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `mmf_holding` (
	`holding_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	`edition_id` INT NOT NULL,
	`lib_name` VARCHAR(255),
	`lib_id` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `mmf_lib` (
	`lib_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	`short_name` VARCHAR(255),
	`full_name` TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `mmf_ref` (
	`ref_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	`work_id` INT NOT NULL,
	`short_name` VARCHAR(255),
	`page_num` INT,
	`ref_work` INT,
	`ref_type` INT NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `mmf_ref_type` (
	`ref_type_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	`name` VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `mmf_error` (
	`error_id` INT AUTO_INCREMENT PRIMARY KEY,
	`filename` VARCHAR(255),
	`edition_id` INT,
	`work_id` INT,
	`text` TEXT,
	`error_note` VARCHAR(255),
	`date` DATE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;