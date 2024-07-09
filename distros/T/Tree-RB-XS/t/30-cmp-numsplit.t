#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::RealBin/lib";
use Test2WithExplain;
use Tree::RB::XS qw/ :key_type :cmp /;
use Time::HiRes 'time';

my @strings= qw(
	10
	20
	20.4.1
	20.4.2
	20.15.1
	foo.20.bar
	foo.7.bar
	2020-1-7_Test
	2020-01-7_Something
	2020-000000000000000000000000000000000000000000000000000000000000001-7_Something
	1test
	2test
	8test
	9test
	10test
	11test
	12test
	999test
	test1test
	Test2test
	test10test
	Test20test
);

my $i= 0;
my %tiebreak= map +( $_ => ++$i ), @strings;
sub numsplit {
	my @a_parts= split /([0-9]+)/, $a;
	my @b_parts= split /([0-9]+)/, $b;
	my $i= 0;
	while ($i < @a_parts || $i < @b_parts) {
		no warnings 'uninitialized';
		my $cmp= ($i & 1)? ($a_parts[$i] <=> $b_parts[$i])
			: ($a_parts[$i] cmp $b_parts[$i]);
		return $cmp if $cmp;
		++$i;
	}
	# Perl's sort doesn't preserve stable order, but the tree does, so the
	# test will fail without this additional tie-breaker.
	return $tiebreak{$a} <=> $tiebreak{$b};
}
#sub numsplit_fc {
#	my @a_parts= split /([0-9]+)/, $a;
#	my @b_parts= split /([0-9]+)/, $b;
#	my $i= 0;
#	while ($i < @a_parts || $i < @b_parts) {
#		no warnings 'uninitialized';
#		my $cmp= ($i & 1)? ($a_parts[$i] <=> $b_parts[$i])
#			: (lc($a_parts[$i]) cmp lc($b_parts[$i])); # lc is close enough for non-unicode tests
#		return $cmp if $cmp;
#		++$i;
#	}
#	# Perl's sort doesn't preserve stable order, but the tree does, so the
#	# test will fail without this additional tie-breaker.
#	return $tiebreak{$a} <=> $tiebreak{$b};
#}


my @perl_sorted= sort { numsplit() } @strings;
#my @perl_fc_sorted= sort { numsplit_fc() } @strings;

my @xs_sorted= sort { Tree::RB::XS::cmp_numsplit($a, $b) } @strings;
is( \@xs_sorted, \@perl_sorted, 'xs cmp_numsplit' );

subtest scalars => sub {
	my $tree= Tree::RB::XS->new(compare_fn => 'numsplit', key_type => KEY_TYPE_ANY, allow_duplicates => 1);
	is( $tree->compare_fn, CMP_NUMSPLIT );
	is( $tree->key_type, KEY_TYPE_ANY );
	$tree->insert($_ => $_) for @strings;
	my @tree_sorted= $tree->iter->next_values('*');
	is( \@tree_sorted, \@perl_sorted );
};

subtest bytestrings => sub {
	my $tree= Tree::RB::XS->new(compare_fn => CMP_NUMSPLIT, key_type => KEY_TYPE_BSTR, allow_duplicates => 1);
	is( $tree->compare_fn, CMP_NUMSPLIT );
	is( $tree->key_type, KEY_TYPE_BSTR );
	$tree->insert($_ => $_) for @strings;
	my @tree_sorted= $tree->iter->next_values('*');
	is( \@tree_sorted, \@perl_sorted );
};

$] >= 5.014000 && subtest unistrings => sub {
	my $tree= Tree::RB::XS->new(compare_fn => CMP_NUMSPLIT, key_type => KEY_TYPE_USTR, allow_duplicates => 1);
	is( $tree->compare_fn, CMP_NUMSPLIT );
	is( $tree->key_type, KEY_TYPE_USTR );
	$tree->insert($_ => $_) for @strings;
	my @tree_sorted= $tree->iter->next_values('*');
	is( \@tree_sorted, \@perl_sorted );
};

#subtest ustrings_fc => sub {
#	my $tree= Tree::RB::XS->new(compare_fn => CMP_NUMSPLIT_FC, key_type => KEY_TYPE_USTR, allow_duplicates => 1);
#	is( $tree->compare_fn, CMP_NUMSPLIT_FC );
#	is( $tree->key_type, KEY_TYPE_USTR );
#	$tree->insert($_ => $_) for @strings;
#	my @tree_sorted= $tree->iter->next_values('*');
#	is( \@tree_sorted, \@perl_fc_sorted );
#};
#
#subtest ustrings_fc => sub {
#	my $tree= Tree::RB::XS->new(compare_fn => CMP_NUMSPLIT_FC, key_type => KEY_TYPE_ANY, allow_duplicates => 1);
#	is( $tree->compare_fn, CMP_NUMSPLIT_FC );
#	is( $tree->key_type, KEY_TYPE_ANY );
#	$tree->insert($_ => $_) for @strings;
#	my @tree_sorted= $tree->iter->next_values('*');
#	is( \@tree_sorted, \@perl_fc_sorted );
#};

done_testing;
