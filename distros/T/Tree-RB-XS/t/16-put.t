#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::RealBin/lib";
use Test2WithExplain;
use Tree::RB::XS qw( CMP_INT CMP_FLOAT CMP_MEMCMP );
use Time::HiRes 'time';

subtest int_tree => sub {
	my $tree= Tree::RB::XS->new(compare_fn => CMP_INT);
	is( $tree->put(1 => 1), undef, 'put new key returns undef' );
	is( $tree->size, 1, 'size=1' );
	is( $tree->put(2 => 2), undef, 'put new key returns undef' );
	is( $tree->size, 2, 'size=2' );
	is( $tree->put(1 => 5), 1, 'put existing key returns old value' );
	is( $tree->put(1 => 2), 5, 'put existing key returns old value' );
	is( $tree->size, 2, 'size=2' );
	ok(eval { $tree->_assert_structure; 1 }, 'structure OK' )
		or diag $@;
	undef $tree; # test destructor
};

subtest float_tree => sub {
	my $tree= Tree::RB::XS->new(compare_fn => CMP_FLOAT);
	is( $tree->put(.50 => 1), undef, 'put new key returns undef' );
	is( $tree->size, 1, 'size=1' );
	is( $tree->put(.75 => 2), undef, 'put new key returns undef' );
	is( $tree->size, 2, 'size=2' );
	is( $tree->put(.50 => 5), 1, 'put existing key returns old value' );
	is( $tree->put(.50 => 2), 5, 'put existing key returns old value' );
	is( $tree->size, 2, 'size=2' );
	ok(eval { $tree->_assert_structure; 1 }, 'structure OK' )
		or diag $@;
	undef $tree; # test destructor
};

subtest str_tree => sub {
	my $tree= Tree::RB::XS->new(compare_fn => CMP_MEMCMP);
	is( $tree->put(x => 1), undef, 'put new key returns undef' );
	is( $tree->size, 1, 'size=1' );
	is( $tree->put(y => 2), undef, 'put new key returns undef' );
	is( $tree->size, 2, 'size=2' );
	is( $tree->put(x => 5), 1, 'put existing key returns old value' );
	is( $tree->put(x => 2), 5, 'put existing key returns old value' );
	is( $tree->size, 2, 'size=2' );
	ok(eval { $tree->_assert_structure; 1 }, 'structure OK' )
		or diag $@;
	undef $tree; # test destructor
};

subtest custom_tree => sub {
	my $tree= Tree::RB::XS->new(compare_fn => sub { $_[0][0] <=> $_[1][0] });
	is( $tree->put([1] => 1), undef, 'put new key returns undef' );
	is( $tree->size, 1, 'size=1' );
	is( $tree->put([2] => 2), undef, 'put new key returns undef' );
	is( $tree->size, 2, 'size=2' );
	is( $tree->put([1] => 5), 1, 'put existing key returns old value' );
	is( $tree->put([1] => 2), 5, 'put existing key returns old value' );
	is( $tree->size, 2, 'size=2' );
	ok(eval { $tree->_assert_structure; 1 }, 'structure OK' )
		or diag $@;
	undef $tree; # test destructor
};

subtest replace_duplicates => sub {
	my $tree= Tree::RB::XS->new(allow_duplicates => 1);
	$tree->put(0,0);
	$tree->insert(1,1);
	my $node1= $tree->max;
	$tree->insert(1,2);
	my $node2= $tree->max;
	$tree->insert(1,3);
	my $node3= $tree->max;
	my $rev_iter= $tree->rev_iter;
	$tree->put(2,5);
	is( $rev_iter->value, 3, 'rev iter on node3' );
	is( $tree->size, 5, 'size=5' );
	is( $tree->exists(1), 3, 'nodes with key=1' );
	is( $tree->put(1,4), 1, 'put returns first of duplicates' );
	is( $tree->size, 3, 'size=3 after put' );
	# Verify nodes are in a sane state
	is( $node1, object {
		call key => 1;
		call value => 4;
		call tree => $tree;
	}, 'node1' );
	is( $node2, object {
		call key => 1;
		call value => 2;
		call tree => undef;
		call newer => undef;
		call older => undef;
	}, 'node2' );
	is( $node3, object {
		call key => 1;
		call value => 3;
		call tree => undef;
		call newer => undef;
		call older => undef;
	}, 'node3' );
	is( $rev_iter, object {
		call key => 1;
		call value => 4;
	}, 'reverse iter moved back to initial node' );
};

subtest put_multi => sub {
	my $tree= Tree::RB::XS->new(allow_duplicates => 1);
	$tree->put_multi(1..10);
	is( $tree->size, 5, 'added 5 pairs' );
	is( $tree->min, object { call key => 1; call value => 2; }, 'min' );
	is( $tree->max, object { call key => 9; call value => 10; }, 'max' );
	$tree->put_multi(1..10);
	is( $tree->size, 5, 'still 5 pairs' );
	is( $tree->min, object { call key => 1; call value => 2; }, 'min' );
	is( $tree->max, object { call key => 9; call value => 10; }, 'max' );
};

subtest comparison_counts => sub {
	my $called= 0;
	my $tree= Tree::RB::XS->new(compare_fn => sub { ++$called; $_[0] <=> $_[1] });
	$tree->put(1);
	is( $called, 0, 'no comparisons to add root node' );
	$tree->put(2);
	is( $called, 1, 'one comparison vs root node'  );
	$called= 0;
	$tree->put(3);
	is( $called, 2, 'compare vs root and right' );
	$called= 0;
	$tree->put(4);
	is( $called, 2, 'compare vs root and right' );
	if ($tree->can('_insert_optimization_debug')) {
		my ($trend, $trigger, $cap, $is_multi)= $tree->_insert_optimization_debug;
		is( $trend, 3, '3 sequential observed' );
	}
	$called= 0;
	$tree->put(5);
	is( $called, 1, 'optimization kicks in, compare to previous' );
	$called= 0;
	is( $tree->put_multi(6..1005), 500, 'add 500 sequential keys' );
	is( $called, 500, 'using 500 comparisons' );

	$tree->clear;
	$called= 0;
	$tree->put(50);
	is( $called, 0, 'no comparisons after clear()' ); # ensure no dangling pointer
};

done_testing;
