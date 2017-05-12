#!/usr/bin/perl
use strict;
use warnings;

# use Xerces/C++ to verify that the .yml tests are correct.  Requires
# the XERCES_DOMCOUNT environment variable to be correctly set to the
# location of a working copy of the DOMCount example program from the
# Xerces/C++ source.

BEGIN {
    unless ($ENV{XERCES_DOMCOUNT}) {
        eval "use Test::More skip_all => 'Test requires \$XERCES_DOMCOUNT';";
    } else {
        eval "use Test::More qw(no_plan);";
    }
}

use lib 't/lib';
use TestRunner qw(test_yml_xerces);

if ($ENV{TEST_YML}) {
    test_yml_xerces($ENV{TEST_YML});
} else {

    # skip tests Xerces doesn't like
    for (sort grep { $_ ne 't/qualified.yml' and
                     $_ ne 't/repeated_groups.yml'
                   } glob('t/*.yml')) {
        print "\n######## $_ #######\n";
        test_yml_xerces($_);
    }
}
