#!perl -w
# Win32::GUI::Constants test suite
# $Id: 70_values.t,v 1.1 2006/05/13 15:39:30 robertemay Exp $
#
# - check that every constant has the expected value

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More;

use FindBin;
my $file = "$FindBin::Bin/70_values.def";

# See if we have the tests, written by the build process:
if(-f $file) {
    do $file;
}
else {
    # The build process should have created the tests
    plan tests => 1;
    fail("Missing test definition file: $file");
}
