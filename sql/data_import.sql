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

MPCE LEGACY DATA IMPORT SCRIPT

AUTHOR: Michael Falk

Over the years, FBTEE has accreted numerous different datasets, which have
been formatted in different ways. Different experiments have been made
to define general table structures that would apply across all datasets.

Now the time has come to prune and consolidate all these datasets, to make
a lean and interpretable database for production. This script grabs the
data from the draft 'manuscripts' database, and ports it across to the new
'mpce' database.

*/
-- Populate keyword_free_associations

INSERT INTO mpce.keyword_free_associations (keyword_1, keyword_2)
SELECT k1.keyword_code AS keyword_1, k2.keyword_code AS keyword_2
FROM manuscripts.keywords AS k1, manuscripts.keywords AS k2, keyword_free_associations AS ka
WHERE
	k1.keyword = ka.keyword AND
	k2.keyword = ka.association;
	
-- Populate keyword_tree_associations

INSERT INTO mpce.keyword_tree_associations (keyword_1, keyword_2)
SELECT k1.keyword_code AS keyword_1, k2.keyword_code AS keyword_2
FROM manuscripts.keywords AS k1, manuscripts.keywords AS k2, keyword_tree_associations AS ka
WHERE
	k1.keyword = ka.keyword AND
	k2.keyword = ka.association;
	
-- Populate stamping
/*
TO DO: client_codes need to be converted to person_codes first.
*/
INSERT INTO stamping (
	stamped_edition, permitted_dealer, attending_inspector, attending_adjoint,
	stamped_at_place, stamped_at_location_type, copies_stamped, volumes_stamped,
	date, ms_number, folio, citation, page_stamped,
	edition_notes, event_notes, article, date_entered, entered_by_user
	)
SELECT ID_EditionName, ID_DealerName, ID_AgentA, ID_AgentB,
	ID_PlaceName, EventLocation, EventCopies, EventVols,
	EventDate, ID_Archive, EventFolioPage, EventCitation, EventPageStamped,
	EventNotes, EventOther, EventArticle, DateEntered, EventUser
FROM manuscripts.manuscript_events;

-- Populate parisian_stock_auction


-- Populate parisian_stock_sale
/*
Some notes:
-	We should split up the sale of privilege from stock sales, because the copies
	are expressed in decimal values, while sales of privilege are expressed as
	fractions
-	The string describing each unit should be replaced with a reference to the
	new 'unit' table
-	The person data needs to be consolidated first, as for other tables
*/
INSERT INTO mpce.parisian_stock_sale


UPDATE manuscripts.manuscript_events_sales 	-- need to make the units match
SET EventCopiesType = 'vols separés'		-- the new table
WHERE EventCopiesType = 'vols';

INSERT INTO mpce.parisian_stock_sale (units)
SELECT u.ID
FROM manuscripts.manuscript_events_sales AS mes, mpce.unit AS u, mpce.parisian_stock_sale AS pss
WHERE
	mes.EventCopiesType = u.definition AND
	mes.ID = pss.ID;