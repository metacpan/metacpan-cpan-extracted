
use strict;
use Test;
use XML::CuteQueries;

my $CQ = XML::CuteQueries
    ->new->parse("<r><p>Slow <em>down</em> there dude.</p></r>");

my @alts = qw(x xml xml());
plan tests => 1+@alts;

ok( $CQ->cute_query(p=>'r'), "Slow down there dude." );
ok( $CQ->cute_query(p=>$_),  "Slow <em>down</em> there dude." ) for @alts;

