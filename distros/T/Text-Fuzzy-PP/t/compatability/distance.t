use strict;
use warnings;

use Test::More tests => 18;
use Text::Fuzzy::PP;


#defaults testing
{
my $tf = Text::Fuzzy::PP->new('four');
is( $tf->distance('fuor'), 2, 'test distance() defaults');
}


#transposition testing
{
my $tf = Text::Fuzzy::PP->new('four',trans => 1);
is( $tf->distance('fuor'), 1, 'test distance() trans => 1');
$tf->transpositions_ok(0);
is( $tf->distance('fuor'), 2, 'test distance() transpositions_ok(0)');
$tf->transpositions_ok(1);
$tf = Text::Fuzzy::PP->new('four',trans => 0);
is( $tf->distance('fuor'), 2, 'test distance() trans => 0');
$tf->transpositions_ok(1);
is( $tf->distance('fuor'), 1, 'test distance() transpositions_ok(1)');
}


#no_exact testing
{
my $tf = Text::Fuzzy::PP->new('four',no_exact => 1);
is( $tf->distance('four'), undef, 'test distance() no_exact => 1');
$tf->no_exact(0);
is( $tf->distance('four'), 0, 'test distance() no_exact(0)');
$tf->no_exact(1);
$tf = Text::Fuzzy::PP->new('four',no_exact => 0);
is( $tf->distance('four'), 0, 'test distance() no_exact => 0');
$tf->no_exact(1);
is( $tf->distance('four'), undef, 'test distance() no_exact(1)');
}


#max_distance testing
{
my $tf = Text::Fuzzy::PP->new('four',max => 1);
is($tf->distance('fuor'), undef, 'test distance with max => 1');
$tf->set_max_distance();
is($tf->distance('fuor'), 2, 'test nearest with set_max_distance()');
$tf->set_max_distance(1);
$tf = Text::Fuzzy::PP->new('four',max => -1);
is($tf->distance('fuor'), 2, 'test nearest with max => undef');
$tf->set_max_distance(1);
is($tf->distance('fuor'), undef, 'test nearest with set_max_distance(1)');
}


#Test some utf8
{
use utf8;
my $tf = Text::Fuzzy::PP->new('ⓕⓞⓤⓡ',trans => 1);
is( $tf->distance('ⓕⓞⓤⓡ'),   0, 'test distance() trans => 1 matching (utf8)');
is( $tf->distance('ⓕⓞⓡ'),    1, 'test distance() trans => 1 insertion (utf8)');
is( $tf->distance('ⓕⓞⓤⓡⓣⓗ'), 2, 'test distance() trans => 1 deletion (utf8)');
is( $tf->distance('ⓕⓤⓞⓡ'),   1, 'test distance() trans => 1 transposition (utf8)');
is( $tf->distance('ⓕⓧⓧⓡ'),   2, 'test distance() trans => 1 substitution (utf8)');
}
