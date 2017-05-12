
use strict;
use Test;
use XML::CuteQueries;
use Data::Dumper;

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent   = 0;

my @e = map { "<$_> " . ord($_) . " </$_>" } 'a' .. 'z';
my $CQ = XML::CuteQueries->new->parse("<r> @e </r>");

plan tests => 2;

ok( Dumper([map {"$_"}  97 .. 120]), Dumper([$CQ->cute_query(  '<re>[a-x]' => '')]) );
ok( Dumper([map {"$_"} 121 .. 122]), Dumper([$CQ->cute_query( '<nre>[a-x]' => '')]) );
