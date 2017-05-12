
use strict;
use Test;
use XML::CuteQueries;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent   = 0;

my $CQ = XML::CuteQueries->new->parse("<r><x><a>1</a></x><x><a>2</a></x></r>");

plan tests => 1;

ok( Dumper({$CQ->hash_query('[]x'=>['a'=>''])}), Dumper({x=>[['1'],['2']]}) );

