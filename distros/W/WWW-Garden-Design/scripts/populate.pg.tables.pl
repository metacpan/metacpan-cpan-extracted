#!/usr/bin/env perl

use strict;
use warnings;

use WWW::Garden::Design::Import::Pg;

# ----------------------------------

WWW::Garden::Design::Import::Pg -> new -> populate_all_tables;
