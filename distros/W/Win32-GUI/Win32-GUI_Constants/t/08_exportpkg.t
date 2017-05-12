#!perl -wT
# Win32::GUI::Constants test suite
# $Id: 08_exportpkg.t,v 1.1 2006/05/13 15:39:30 robertemay Exp $
#
# - check we can export to a specified package

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More tests => 4;

use Win32::GUI::Constants (-exportpkg => 'Cnst', 'CW_USEDEFAULT');

# Test exporting of constant
can_ok("Cnst", "CW_USEDEFAULT");

ok(!defined(&Cnst::CW_USEDEFAULT), "default constant not defined");
is(Cnst::CW_USEDEFAULT, 2147483648, "correct value");
ok(defined(&Cnst::CW_USEDEFAULT), "default constant defined after calling it");
