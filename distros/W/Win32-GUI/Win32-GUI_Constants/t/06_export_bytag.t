#!perl -wT
# Win32::GUI::Constants test suite
# $Id: 06_export_bytag.t,v 1.1 2006/05/13 15:39:30 robertemay Exp $
#
# - check exporting by tag

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More tests => 8;

use Win32::GUI::Constants qw(:all);

# Test exporting
can_ok("main", "ES_WANTRETURN");
can_ok("main", "ERROR");

ok(!defined(&ES_WANTRETURN), "ES_WANTRETURN constant not defined");
is(ES_WANTRETURN, 4096, "correct value");
ok(defined(&ES_WANTRETURN), "ES_WANTRETURN constant defined after calling it");

ok(!defined(&ERROR), "ERROR constant not defined");
is(ERROR, 0, "correct value");
ok(defined(&ERROR), "ERROR constant defined after calling it");
