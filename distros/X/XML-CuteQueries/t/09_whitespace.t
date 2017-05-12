
use strict;
use Test;
use XML::CuteQueries;
use Data::Dumper;

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent   = 0;

my $CQ = XML::CuteQueries->new->parse("<r> <x> 7</x> <x> 7  \n</x></r>");

plan tests => 3;

ok( Dumper($CQ->cute_query({notrim=>1}, '.'=>[x=>''])), Dumper([' 7', " 7  \n"]) );
ok( Dumper([$CQ->cute_query(x=>'')]), Dumper(['7', " 7  \n"]) );

# note that [$CQ->cute_query(matches)] is pretty much the same as $CQ->cute_query('.'=>[matches]) now

ok( Dumper( $CQ->cute_query({notrim=>1, nofilter_nontags=>1}, '.'=>['*'=>'r']) ),
    Dumper([' ', ' 7', ' ', " 7  \n"]) );
