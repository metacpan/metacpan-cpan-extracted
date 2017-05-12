#!/usr/bin/perl

use strict;
use warnings;

use Test::More skip_all => 'This module is deprecated!';
# use Test::More tests => 6;

# TEST
BEGIN { use_ok('WWW::Search'); };
# TEST
BEGIN { use_ok('WWW::Search::Test'); };
# TEST
BEGIN { use_ok('WWW::Search::MSN'); };

$WWW::Search::Test::oSearch = new WWW::Search('MSN');
# TEST
isa_ok ($WWW::Search::Test::oSearch, "WWW::Search");
$WWW::Search::Test::oSearch->env_proxy('yes');

my $debug = 0;
my $dump  = 0;

$debug = 0;
$dump = 0;

# Generate a simple string that does not exist anywhere else
my $string1 = 'n0neks1sfng';
my $string2 = 'dnder34hg328vnnblkngm23';

$string2 =~ tr/a-z/bacdghuyjvbkmlllkmzxlcmlz/;

my $count =
    WWW::Search::Test::count_results(
        'normal',
        "$string1$string2",
        0,
        49,
        $debug,
        $dump
    );

# TEST
is ($WWW::Search::Test::oSearch->approximate_result_count(), 0,
    "approximate_result_count is 0");

my @results = $WWW::Search::Test::oSearch->results();

# TEST
is (scalar(@results), 0, "Checking for results");

