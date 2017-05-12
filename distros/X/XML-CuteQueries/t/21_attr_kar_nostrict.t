
use strict;
use Test;
use XML::CuteQueries;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent   = 0;

my $CQ = XML::CuteQueries->new->parse(q{ <r>

    <meta>blarg1</meta>
    <meta>blarg2</meta>
    <meta>blarg3</meta>

    <meta>test1</meta>
    <meta>test2</meta>
    <meta>test3</meta>

</r> });

plan tests => 4;

ok( Dumper({ $CQ->hash_query(                      '[]*'=>'') }), Dumper({meta=>[qw(blarg1 blarg2 blarg3 test1 test2 test3)]}) );
ok( Dumper({ $CQ->hash_query({nostrict_match=>1},  '[]*'=>'') }), Dumper({meta=>[qw(blarg1 blarg2 blarg3 test1 test2 test3)]}) );
ok( Dumper({ $CQ->hash_query({nostrict_single=>1}, '[]*'=>'') }), Dumper({meta=>[qw(blarg1 blarg2 blarg3 test1 test2 test3)]}) );
ok( Dumper({ $CQ->hash_query({nostrict=>1},        '[]*'=>'') }), Dumper({meta=>[qw(blarg1 blarg2 blarg3 test1 test2 test3)]}) );
