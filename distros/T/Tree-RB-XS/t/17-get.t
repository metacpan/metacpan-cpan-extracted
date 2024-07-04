#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::RealBin/lib";
use Test2WithExplain;
use Tree::RB::XS qw( KEY_TYPE_INT KEY_TYPE_FLOAT KEY_TYPE_BSTR KEY_TYPE_ANY );
use Time::HiRes 'time';

my $node_cnt= $ENV{TREERBXS_TEST_NODE_COUNT} || 100000;

subtest int_tree => sub {
	my $tree= Tree::RB::XS->new(key_type => KEY_TYPE_INT);
	for (0..-1+$node_cnt) {
		$tree->put($_ => $_);
	}
	for (1..50) {
		my $k= int rand $node_cnt;
		my $x= $tree->get($k);
		is( $x, $k ); 
	}
	ok(eval { $tree->_assert_structure; 1 }, 'structure OK' )
		or diag $@;
	undef $tree; # test destructor
};

subtest float_tree => sub {
	my $tree= Tree::RB::XS->new(key_type => KEY_TYPE_FLOAT);
	for (0..-1+$node_cnt) {
		$tree->put($_/8 => $_/8);
	}
	for (1..50) {
		my $k= int(rand $node_cnt)/8;
		my $x= $tree->get($k);
		is( $x, $k ); 
	}
	ok(eval { $tree->_assert_structure; 1 }, 'structure OK' )
		or diag $@;
	undef $tree; # test destructor
};

subtest str_tree => sub {
	my $tree= Tree::RB::XS->new(key_type => KEY_TYPE_BSTR);
	for (0..-1+$node_cnt) {
		$tree->put("x$_" => "x$_");
	}
	for (1..50) {
		my $k= 'x' . int rand $node_cnt;
		my $x= $tree->get($k);
		is( $x, $k ); 
	}
	ok(eval { $tree->_assert_structure; 1 }, 'structure OK' )
		or diag $@;
	undef $tree; # test destructor
};

subtest custom_tree => sub {
	my $tree= Tree::RB::XS->new(key_type => KEY_TYPE_ANY, compare_fn => sub { $_[0][0] <=> $_[1][0] });
	for (0..-1+$node_cnt) {
		$tree->put([$_] => [$_]);
	}
	for (1..50) {
		my $k= [int rand $node_cnt];
		my $x= $tree->get($k);
		is( $x, $k ); 
	}
	ok(eval { $tree->_assert_structure; 1 }, 'structure OK' )
		or diag $@;
	undef $tree; # test destructor
};

subtest get_all => sub {
	my $tree= Tree::RB::XS->new;
	$tree->allow_duplicates(1);
	$tree->insert($_ => $_) for 1..20;
	$tree->insert(5 => 'X'.(5-$_)) for 0..4;
	is( [ $tree->get_all(5) ], [qw( 5 X5 X4 X3 X2 X1 )], 'all values, in insertion order' );
};

done_testing;
