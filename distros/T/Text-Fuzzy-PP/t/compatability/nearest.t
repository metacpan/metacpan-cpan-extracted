use strict;
use warnings;

use Test::More tests => 14;
use Text::Fuzzy::PP;

my @list = ('fourtyx','fxxr','fourth','fuor','');


#defaults testing
{
my $tf = Text::Fuzzy::PP->new('four');
is( $list[$tf->nearest(\@list)], 'fxxr', 'test nearest defaults');
}


#transposition testing
{
my $tf = Text::Fuzzy::PP->new('four',trans => 1);
is( $list[$tf->nearest(\@list)], 'fuor', 'test nearest with trans => 1');
$tf->transpositions_ok(0);
is( $list[$tf->nearest(\@list)], 'fxxr', 'test nearest with transposition_ok(0)');
$tf->transpositions_ok(1);
$tf = Text::Fuzzy::PP->new('four',trans => 0);
is( $list[$tf->nearest(\@list)], 'fxxr', 'test nearest with trans => 0');
$tf->transpositions_ok(1);
is( $list[$tf->nearest(\@list)], 'fuor', 'test nearest with transposition_ok(1)');
}


#no_exact testing
{
push @list, 'four'; # add exact match
my $tf = Text::Fuzzy::PP->new('four',no_exact => 1);
is( $list[$tf->nearest(\@list)], 'fxxr', 'test nearest with no_exact => 1');
$tf->no_exact(0);
is( $list[$tf->nearest(\@list)], 'four', 'test nearest with no_exact(0)');
$tf->no_exact(1);
$tf = Text::Fuzzy::PP->new('four',no_exact => 0);
is( $list[$tf->nearest(\@list)], 'four', 'test nearest with no_exact => 0');
$tf->no_exact(1);
is( $list[$tf->nearest(\@list)], 'fxxr', 'test nearest with no_exact(1)');
pop @list; # remove exact match
}


#max_distance testing
{
my $tf = Text::Fuzzy::PP->new('....',max => 1);
is( $tf->nearest(\@list), undef, 'test nearest with max => 1');
$tf->set_max_distance();
is( $list[$tf->nearest(\@list)], 'fxxr', 'test nearest with set_max_distance()');
$tf->set_max_distance(1);
$tf = Text::Fuzzy::PP->new('....',max => -1);
is( $list[$tf->nearest(\@list)], 'fxxr', 'test nearest with max => -1');
$tf->set_max_distance(1);
is( $tf->nearest(\@list), undef, 'test nearest with set_max_distance(1)');
}


#Test some utf8
{
use utf8;
my $tf = Text::Fuzzy::PP->new('ⓕⓞⓤⓡ',trans => 1);
my @list = ('ⓕⓤⓞⓡ','ⓕⓞⓤⓡⓣⓗ','ⓕⓧⓧⓡ','');
is( $list[$tf->nearest(\@list)], 'ⓕⓤⓞⓡ', 'test nearest with transposition (utf8)');
}