
use strict;
use Test;
use XML::CuteQueries;

my $CQ = XML::CuteQueries->new->parse("<r><x><y>7</y><a>7</a><a>8</a></x></r>");

plan tests => 24;

ok( $CQ->cute_query('x/y' => ''), 7 );
ok( eval{$CQ->cute_query('x/z' => '')}, undef ) and ok($@, qr(match failed));
ok( $CQ->cute_query({nostrict_match=>1}, 'x/z' => ''), undef );
ok( $CQ->cute_query({nostrict=>1}, 'x/z' => ''), undef );

ok( eval{$CQ->cute_query("x/a"=>'')}, undef) and ok($@, qr(single-value));
ok( $CQ->cute_query({nostrict_single=>1}, "x/a"=>''), 7);

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent   = 0;
my $exemplar = Dumper({y=>'7', a=>'8'});

ok( eval{$CQ->cute_query(x=>{'*'=>''})}, undef ) and ok($@, qr(match-per-tagname));
ok( Dumper($CQ->cute_query({nostrict_single=>1}, x=>{'*'=>''})), $exemplar );
ok( Dumper($CQ->cute_query({nostrict=>1}, x=>{'*'=>''})), $exemplar );

$CQ->parse("<r><x><a>1</a></x><x><a>2</a></x></r>");
ok( eval{$CQ->hash_query(x=>[])}, undef ) and ok($@, qr(match-per-tagname));
ok( eval{$CQ->cute_query('.'=>{x=>[]})}, undef ) and ok($@, qr(match-per-tagname));
ok( eval{$CQ->hash_query(x=>{})}, undef ) and ok($@, qr(match-per-tagname));
ok( eval{$CQ->cute_query('.'=>{x=>{}})}, undef ) and ok($@, qr(match-per-tagname));

my $e_ar = Dumper({x=>[]});
my $e_ha = Dumper({x=>{}});

ok( Dumper({$CQ->hash_query({nostrict=>1}, x=>[])}),      $e_ar );
ok( Dumper($CQ->cute_query({nostrict=>1}, '.'=>{x=>[]})), $e_ar );
ok( Dumper({$CQ->hash_query({nostrict=>1}, x=>{})}),      $e_ha );
ok( Dumper($CQ->cute_query({nostrict=>1}, '.'=>{x=>{}})), $e_ha );
