#!perl -wT
# Win32::GUI::Constants test suite
# $Id: 02_default.t,v 1.1 2006/05/13 15:39:30 robertemay Exp $
#
# - check a single constant export

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More tests => 8;

use Win32::GUI::Constants qw(CW_USEDEFAULT);

# Test exporting of constant
can_ok("main", "CW_USEDEFAULT");

ok(!defined(&CW_USEDEFAULT), "default constant not defined");
is(CW_USEDEFAULT, 2147483648, "correct value");
ok(defined(&CW_USEDEFAULT), "default constant defined after calling it");

# Test other symbol not exported
ok(!main->can("ES_WANTRETURN"), "main->can('ES_WANTRETURTN') failed");

# Test autoloading of constant
ok(!defined(&Win32::GUI::Constants::ES_WANTRETURN), "constant not defined");
is(Win32::GUI::Constants::ES_WANTRETURN(), 4096, "correct value");
ok(defined(&Win32::GUI::Constants::ES_WANTRETURN),"constant defined after calling it");
