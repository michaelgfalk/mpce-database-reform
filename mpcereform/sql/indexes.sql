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

Indexes for mpce database.

This script creates indexes to speed up common queries on the MPCE
database. It is executed after buliding the database to speed the
process.

*/

/*

1. UNIQUE INDEXES FOR VALIDATING JOINS

*/

