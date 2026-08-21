#!/usr/bin/env perl

use strict;
use warnings;

use WWW::Garden::Design::Import::SQLite;

# --------------------------------------

WWW::Garden::Design::Import::SQLite -> new -> populate_all_tables;
