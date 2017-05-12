
use strict;
use Test;
use XML::CuteQueries;

my $CQ = XML::CuteQueries
    ->new->parse("<r><p>Slow <em>down</em> there dude.</p></r>");

my @alts = qw/r a recurse all recurse_text all_text recurse() all() recurse_text() all_text()/;
plan tests => 1 + @alts;

ok( $CQ->cute_query(p=>''), "Slow  there dude." );
ok( $CQ->cute_query(p=>$_), "Slow down there dude." ) for @alts;

