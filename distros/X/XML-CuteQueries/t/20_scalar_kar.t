
use strict;
use Test;
use XML::CuteQueries;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent   = 0;

my $CQ = XML::CuteQueries->new->parse("<r><x><a>1</a></x><x><a>2</a></x></r>");

plan tests => 6;

ok( Dumper({$CQ->hash_query('[]x'=>'x')}), Dumper({x=>[qw(<a>1</a> <a>2</a>)]}) );
ok( Dumper({$CQ->hash_query('[]x'=>'r')}), Dumper({x=>[qw(1 2)]}) );
ok( Dumper({$CQ->hash_query('[]x'=>'')}),  Dumper({x=>['', '']}) );

my $c = 0;
my %res = $CQ->hash_query('[]x'=>'t');
for my $t (@{ $res{x} }) {
    $c ++ if $t->gi eq "x";
}
ok($c, 2);

$CQ->parse("<r><x><a>  1   </a></x><x><a>  2   </a></x></r>");
ok( Dumper({$CQ->hash_query('[]x'   => 'r')}), Dumper({x=>[qw(1 2)]}) );
ok( Dumper({$CQ->hash_query('[]x/a' => '')}),  Dumper({a=>[qw(1 2)]}) );
