#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::RealBin/lib";
use Test2WithExplain;
use Tree::RB::XS qw( KEY_TYPE_INT KEY_TYPE_FLOAT KEY_TYPE_BSTR KEY_TYPE_ANY );
use Time::HiRes 'time';

my $node_cnt= $ENV{TREERBXS_TEST_NODE_COUNT} || 1000000;

subtest int_tree => sub {
	my $tree= Tree::RB::XS->new(key_type => KEY_TYPE_INT);
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
	my $tree= Tree::RB::XS->new(key_type => KEY_TYPE_FLOAT);
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
	my $tree= Tree::RB::XS->new(key_type => KEY_TYPE_BSTR);
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
	my $tree= Tree::RB::XS->new(key_type => KEY_TYPE_ANY, compare_fn => sub { $_[0][0] <=> $_[1][0] });
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

done_testing;
