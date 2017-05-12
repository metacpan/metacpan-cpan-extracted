#!/usr/bin/env perl
#
# This file is part of Test-NoSmartComments
#
# This software is Copyright (c) 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#

use Test::More tests => 1;

BEGIN {
    use_ok( 'Test::NoSmartComments' );
}

diag("Testing Test::NoSmartComments $Test::NoSmartComments::VERSION, Perl $], $^X");
