#!perl

use utf8;
use strict;
use warnings;
use Test::More;
use Text::Amuse::Preprocessor::TypographyFilters;

my $filter = Text::Amuse::Preprocessor::TypographyFilters::specific_filter('zh');
ok $filter, "Filter for chinese exists";
my @tests = (
             # in          , #out           , # comment
             [ "string",   "string",   "Test in/out" ],
             [ "string 2", "string 2", "Nothing changes" ],
            );

foreach my $test (@tests) {
    is $filter->($test->[0]), $test->[1], $test->[2];
}

done_testing;
