#!/usr/bin/perl

use strict;
use warnings;

# use Test::More tests => 108;
#
use Test::More skip_all => "This module is deprecated!";

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

my $count =
    WWW::Search::Test::count_results(
        'normal',
        'firs' . 't co' . 'me f' . 'irst se' . 'rved',
        0,
        49,
        $debug,
        $dump
    );

# TEST
ok (($WWW::Search::Test::oSearch->approximate_result_count() =~ /^\d+$/),
    "approximate_result_count is a number");

# TEST
ok (($WWW::Search::Test::oSearch->approximate_result_count() > 0),
    "approximate_result_count is greater than 0");

# TEST
is ($count, 50, "Checking for count");

my @results = $WWW::Search::Test::oSearch->results();

# TEST
is (scalar(@results), 50, "Checking for results");

# TEST*2*50
foreach my $r (@results)
{
    like ($r->url(), qr{\Ahttp(?:s?)://},
        'Result URL is http');
    ok ((length($r->title()) > 0), "Has a non-empty title");
}

