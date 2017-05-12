#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;

# TEST
BEGIN { use_ok('WWW::Search'); };
# TEST
BEGIN { use_ok('WWW::Search::Test'); };
# TEST
BEGIN { use_ok('WWW::Search::AOL'); };

$WWW::Search::Test::oSearch = new WWW::Search('AOL');
# TEST
isa_ok ($WWW::Search::Test::oSearch, "WWW::Search");
$WWW::Search::Test::oSearch->env_proxy('yes');

my $debug = 0;
my $dump  = 0;

$debug = 0;
$dump = 0;

my $count =
    WWW::Search::Test::count_results(
        'normal',
        'link:http://wnviuncsivndkvndvjnbpwnvinsvdiondvs.goj/',
        0,
        49,
        $debug,
        $dump
    );

# TEST
is ($WWW::Search::Test::oSearch->approximate_result_count(), 0,
    "approximate_result_count is 0 for no results found search.");

# TEST
is ($count, 0, "Checking for count of no results found search");

my @results = $WWW::Search::Test::oSearch->results();

# TEST
is_deeply (\@results, [], "Checking for results of no results found search");

