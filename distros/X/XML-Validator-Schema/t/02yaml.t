#!/usr/bin/perl
use strict;
use warnings;
use lib 't/lib';

use Test::More qw(no_plan);
use TestRunner qw(test_yml foreach_parser);

foreach_parser {
    if ($ENV{TEST_YML}) {
        test_yml($ENV{TEST_YML});
    } else {
        for (sort glob('t/*.yml')) {
            print "\n######## $_ #######\n";
            test_yml($_);
        }
    }    
};
