#!perl -wT
# Win32::GUI::Constants test suite
# $Id: 03_inline.t,v 1.1 2006/05/13 15:39:30 robertemay Exp $
#
# - check inlining a single constant export

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More tests => 3;

use Win32::GUI::Constants qw(-inline CW_USEDEFAULT);

# Test exporting of constant
can_ok("main", "CW_USEDEFAULT");

# If the function is defined at this stage it can be inlined
ok(defined(&CW_USEDEFAULT), "exported symbol will be inlined");
ok(defined(&Win32::GUI::Constants::CW_USEDEFAULT),"symbol will be inlined");
