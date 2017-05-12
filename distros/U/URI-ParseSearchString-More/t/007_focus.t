# -*- perl -*-

use strict;
use warnings;

# t/007_focus.t - focus on some troublesome URLs

use Test::Most;

use URI::ParseSearchString::More;

my $more = URI::ParseSearchString::More->new();
isa_ok( $more, 'URI::ParseSearchString::More' );

my @engines = $more->_get_engines;
ok( @engines, "got a list of engines" );

my $terms
    = $more->parse_search_string(
    "http://www.fastbrowsersearch.com/results/results.aspx?s=NAUS&v=13&tid={C5854863-3CC1-1DED-613C-A9E844BDCC77}&q=how to get a headline on myspace2.0"
    );

cmp_ok(
    $terms, 'eq',
    "how to get a headline on myspace2.0",
    "got correct terms for fastbrowsersearch"
);

done_testing();
