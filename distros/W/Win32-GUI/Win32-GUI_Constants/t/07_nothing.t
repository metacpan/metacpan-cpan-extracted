#!perl -wT
# Win32::GUI::Constants test suite
# $Id: 07_nothing.t,v 1.1 2006/05/13 15:39:30 robertemay Exp $
#
# - check that we can export nothing

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More tests => 6;

use Win32::GUI::Constants ();

# Test exporting of constant
ok(!main->can("CW_USEDEFAULT"), "a symbol not exported");

# Test calling pkg directly
ok(!Win32::GUI::Constants->can("ES_WANTRETURN"), "ES_WANTRETURN not available");
ok(!defined(&Win32::GUI::Constants::ES_WANTRETURN), "constant not defined");
is(Win32::GUI::Constants::ES_WANTRETURN(), 4096, "correct value");
ok(defined(&Win32::GUI::Constants::ES_WANTRETURN),"constant defined after calling it");
can_ok("Win32::GUI::Constants", "ES_WANTRETURN");
