# mpce-database-reform
Reshaping years of FBTEE data into a clean new database.

## Overview

This package serves a bespoke purpose: to import data from version one of the [FBTEE](http://fbtee.uws.edu.au/main/) database, combine it with new data tables generated in the ensuing years, and ingest additional research data from spreadsheets. Other users are unlikely to find it useful, but it makes the provenance of the project's research data clear for other scholars.

In order to combine multiple datasets, this package also restructures how persons and corporate entities are referred to in all the datasets. The new concept of an 'agent' is introduced, and all persons and entities are combined into a single list of 'agents'.

## Getting started

The package has a command-line interface. Once it is installed, you can run the routines directly from your terminal. To run the package, you need to have:

* `Python 3.7` installed on your machine.
* `git` installed on your machine.
* Access to a MySQL/MariaDB database, which has the development version of the **FBTEE** database installed, called `manuscripts`. The SQL for the `manuscripts` database is available in the `mpcereform/sql` directory of this repository.

Next, download this repository:

```
cd directory/where/you/would/like/to/save/
git clone https://github.com/michaelgfalk/mpce-database-reform

# cloning into directory/where/you/would/like/to/save/mpce-database-reform
```

Then install it on your machine using `pip` or `easy_install`. You might like to do this in a [virtual environment](https://docs.python.org/3/library/venv.html):

```
cd directory/you/chose/mpce-database-reform
pip install . -r requirements.txt
```

This will install the python package `mpcereform`, which you can call from within your own python script, and will also install the command line tool `reform-db`. If you wish to build your own copy of the **FBTEE** database, and you have a copy of the `manuscripts` database on your machine, then you can simply type the following a the command line, supplying your MySQL/MariaDB username and password:

```
reform-db -u your_username -p your_password
```

For help on using `reform-db`, simply type:

```
reform-db --help
```

## FBTEE-2.0

In the coming months, the updated version of the FBTEE database will be available online, and the raw SQL will be freely available to download. Please check back here, or at [our project blog](https://frenchbooktrade.wordpress.com/) for updates.

## MMF-2

The schema included in this repo contains table definitions for the MMF-2 database. But it does not import the data into the tables, and the SQL does not necessarily represent the most up-to-date version of the schema. Please see the [mmf-parser project](https://github.com/michaelgfalk/mmf-parser) for the latest build scripts for the **MMF-2** tables.

## Credits

* **Michael Falk** (maintainer), Developer and Research Project Manager, Digital Humanities Research Group, Western Sydney University
* **Simon Burrows**, project lead, database design
* **Rachel Hendery**, co-chief investigator, methodology
* **Tomas Trescak**, co-chief investigator, front-end developer
* **Angus Martin**, co-chief investigator, database design, data entry
* **Laure Philip**, data entry
* **Katie McDonough**, data entry, database design
* **Jason Ensor**, database design
* **Juliette Reboul**, data entry

## License

MIT. See attached license file.
