#!/usr/bin/env perl

use strict;
use warnings;

use oEdtk::EDMS qw(EDMS_process_zip);

if (@ARGV < 2 or $ARGV[0] =~/-h/i) {
	warn "Usage: $0 <ged.zip> <outdir>\n\n";
	warn "\tThis process ged.zip to load index and prepare pdf docs for loading in EDMS system.\n";
	warn "\tpdf and index should have the same name and should use uniq id (see index structure).\n";
	exit 1;
}

EDMS_process_zip($ARGV[0], $ARGV[1]);
