#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::RealBin/lib";
use Test2WithExplain;
use Tree::RB::XS qw( KEY_TYPE_INT KEY_TYPE_FLOAT );
use Time::HiRes 'time';

sub err(&) { my $code= shift; local $@; eval { $code->() }; my $err= "$@"; return $err; }

subtest error_unless_int_or_float => sub {
	my $tree= Tree::RB::XS->new(key_type => KEY_TYPE_INT, kv => [ 1,1 ]);
	is( err { $tree->rekey(offset => 1) }, '', 'int' );

	$tree= Tree::RB::XS->new(key_type => KEY_TYPE_FLOAT, kv => [ 1,1 ]);
	is( err { $tree->rekey(offset => 1.1) }, '', 'float' );

	$tree= Tree::RB::XS->new(kv => [ 1,1 ]);
	like( err { $tree->rekey(offset => 1) }, qr/integer or float/, 'any' );

	$tree= Tree::RB::XS->new(compare_fn => 'numsplit', kv => [ 1,1 ]);
	like( err { $tree->rekey(offset => 1) }, qr/integer or float/, 'str' );
};

subtest rekey_int_basic => sub {
	my $tree= Tree::RB::XS->new(compare_fn => 'int');
	$tree->rekey(offset => 1);
	is( $tree->size, 0, 'empty tree' );
	$tree->put(1,1);
	$tree->rekey(offset => 2);
	is( [$tree->kv], [ 3,1 ], 'move one key 1 => 3' );
	$tree->put(1,2);
	$tree->rekey(offset => 1);
	is( [$tree->kv], [ 2,2, 4,1 ], 'move two keys' );
	$tree->rekey(offset => 1.5);
	is( [$tree->kv], [ 3,2, 5,1 ], 'truncate NV offset to integer' );
	$tree->rekey(offset => -10);
	is( [$tree->kv], [ -7,2, -5,1 ], 'negative offset' );
};

subtest rekey_int_overflow => sub {
	my $uint_max= unpack "J", ("\xFF"x16);
	my $int_max= $uint_max >> 1;
	my $int_min= -$int_max - 1;
	note "uint_max=$uint_max, int_max=$int_max, int_min=$int_min";

	my $tree= Tree::RB::XS->new(compare_fn => 'int', kv => [-1,-1, 1,1]);
	# max key is 1, plus INT_MAX would overflow
	like( err { $tree->rekey(offset => $int_max) }, qr/overflow/, 'int_max overflow' );
	# min key is -1, plus INT_MIN would overflow
	like( err { $tree->rekey(offset => $int_min) }, qr/overflow/, 'int_min overflow' );
	# 0 + int_max is in_max, which should be ok
	$tree= Tree::RB::XS->new(compare_fn => 'int', kv => [0,0]);
	like( err { $tree->rekey(offset => $int_max) }, '', '0 + int_max' );
	is( [$tree->keys], [$int_max] );
	# 0 + int_max is in_max, which should be ok
	$tree= Tree::RB::XS->new(compare_fn => 'int', kv => [0,0]);
	like( err { $tree->rekey(offset => $int_min) }, '', '0 + int_min' );
	is( [$tree->keys], [$int_min] );
	# check handling of unsigned
	$tree= Tree::RB::XS->new(compare_fn => 'int', kv => [$int_min+1,'min']);
	like( err { $tree->rekey(offset => $uint_max) }, qr/not supported/, 'uint_max not supported' );
};

subtest rekey_int_conflict => sub {
	my $tree= Tree::RB::XS->new(compare_fn => 'int', kv => [ 1,1, 2,2, 5,5, 6,6, 7,7 ]);
	$tree->rekey(offset => -2, min => 5);
	is( [$tree->kv], [ 1,1, 2,2, 3,5, 4,6, 5,7 ], 'remove gap in keys' );
	$tree->rekey(offset => 2, min => 2);
	is( [$tree->kv], [ 1,1, 4,2, 5,5, 6,6, 7,7 ], 'insert gap in keys' );
	$tree->rekey(offset => -3, min => 2);
	is( [$tree->kv], [ 1,2, 2,5, 3,6, 4,7 ], 'clobber key 1' );
	$tree->rekey(offset => 10);
	$tree->put(1,1);
	$tree->put(20,20);
	$tree->rekey(offset => 1, min => 9, max => 19);
	is( [$tree->kv], [ 1,1, 12,2, 13,5, 14,6, 15,7, 20,20 ], 'move when double bounded' );

	$tree= Tree::RB::XS->new(compare_fn => 'int', kv => [ 2,2, 4,4, 6,6, 8,8, 10,10, 12,12, 14,14, 16,16, 18,18, 20,20 ]);
	$tree->rekey(offset => -9, min => 10);
	is( [$tree->kv], [ 1,10, 2,2, 3,12, 4,4, 5,14, 6,6, 7,16, 8,8, 9,18, 11,20 ], 'interleave' );
};

subtest rekey_float_basic => sub {
	my $tree= Tree::RB::XS->new(compare_fn => 'float', kv => [ 1,1, 2,2, 4,4, 8,8 ]);
	$tree->rekey(offset => 1);
	is( [$tree->kv], [ 2,1, 3,2, 5,4, 9,8 ], 'shift float by 1' );
};

subtest rekey_min_to_max => sub {
	my $tree= Tree::RB::XS->new(compare_fn => 'int', kv => [ 1,1, 2,2, 3,3 ]);
	$tree->rekey(offset => 10, min => $tree->min_node, max => $tree->max_node);
	is( [$tree->kv], [ 11,1, 12,2, 13,3 ], 'offset 10 from min_node to max_node' );
	
	$tree= Tree::RB::XS->new(compare_fn => 'int', kv => [ 1,1, 2,2, 3,3 ]);
	$tree->rekey(offset => 10, min => $tree->iter, max => $tree->rev_iter);
	is( [$tree->kv], [ 11,1, 12,2, 13,3 ], 'offset 10 from iter to rev_iter' );
};

done_testing;
