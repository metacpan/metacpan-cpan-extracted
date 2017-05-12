#!perl -wT
# Win32::GUI::Constants test suite
# $Id: 04_noexport.t,v 1.1 2006/05/13 15:39:30 robertemay Exp $
#
# - check inlining a single non-exported constant

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More tests => 2;

use Win32::GUI::Constants qw(-noexport CW_USEDEFAULT);

# Test exporting of constant
ok(!main->can("CW_USEDEFAULT"), "Default symbol not exported");

# If the function is defined at this stage it can be inlined
ok(defined(&Win32::GUI::Constants::CW_USEDEFAULT),"symbol will be inlined");
