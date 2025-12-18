#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::RealBin/lib";
use Test2WithExplain;
use Tree::RB::XS qw( KEY_TYPE_INT KEY_TYPE_FLOAT KEY_TYPE_USTR KEY_TYPE_BSTR KEY_TYPE_ANY
   CMP_PERL CMP_STR CMP_FOLDCASE );
use Time::HiRes 'time';

{ package canary;
  our @dead;
  sub new { my $x= $_[1]; bless \$x, $_[0] }
  sub DESTROY { push @dead, ${$_[0]} }
}

my $tree= Tree::RB::XS->new(key_type => KEY_TYPE_INT);
$tree->put(1 => 2);
my $node= $tree->min_node;
is( $node, object {
	call key => 1;
	call value => 2;
	call count => 1;
	call color => 0;
	call parent => undef;
	call left   => undef;
	call right  => undef;
	call next   => undef;
	call prev   => undef;
	call older  => undef;
	call newer  => undef;
	call recent_tracked => F;
});

is( $tree->max_node,     $node, 'max node same as min' );
is( $tree->nth_node(0),  $node, 'index up from 0' );
is( $tree->nth_node(-1), $node, 'index down from size' );
is( $tree->nth_node(1),  undef, 'no node 1' );

for (1..9) { $tree->put($_ => $_); }
for (2..9) { is( ($node= $node->next)->value, $_, "next -> $_" ) }
is( $node->next, undef, 'end' );

is( $tree->nth_node(5)->value, 6, 'nth(5)' );

subtest all_key_types => sub {
	# Ensure the 'key' accessor can read all types of keys
	for (KEY_TYPE_ANY, KEY_TYPE_INT, KEY_TYPE_FLOAT, KEY_TYPE_USTR, KEY_TYPE_BSTR) {
		my $tree= Tree::RB::XS->new(key_type => $_);
		$tree->put(42 => 1);
		is( $tree->min_node->key, 42, "key from type $_" );
	}
};

subtest lvalue => sub {
	my $tree= Tree::RB::XS->new;
	$tree->insert(5);
	$tree->get_node(5)->value= 6;
	++$tree->get_node(5)->value;
	is( $tree->min_node, object {
		call key => 5;
		call value => 7;
	});
};

subtest prune => sub {
	my $tree= Tree::RB::XS->new(kv => [ x => 2, 42 => 1 ]);
	is( $tree->size, 2, '2 nodes before prune' );
	ok( my $x= $tree->get_node('x') );
	is( $x->prev, $tree->max_node, 'has next' );
	is( $x->prune, 1, 'remove "x"' );
	is( $x->prev, undef, 'no longer has next' );
	is( $x->prune, 0, 'already removed' );
	is( $x, object {
		call key => 'x';
		call value => 2;
		call count => 0;
		call color => 0;
		call parent => undef;
		call left   => undef;
		call right  => undef;
		call next   => undef;
		call prev   => undef;
		call older  => undef;
		call newer  => undef;
		call tree   => undef;
		call recent_tracked => F;
	}, 'no crashes when tree is undef');
	is( $tree->size, 1, '1 node after prune' );
	is( $tree->min->key, 42 );
	is( $tree->min->prune, 1, 'remove last node' );
	is( $tree->size, 0, 'tree empty' );
};

subtest dangling_node => sub {
	my $tree= Tree::RB::XS->new(kv => [ x => 2, y => 3 ]);
	my $node1= $tree->min;
	my $node2= $tree->max;
	undef $tree;
	is( $node1, object {
		call key => 'x';
		call value => 2;
		call count => 0;
		call parent => undef;
		call left   => undef;
		call right  => undef;
		call next   => undef;
		call prev   => undef;
		call older  => undef;
		call newer  => undef;
		call tree   => undef;
		call recent_tracked => F;
	}, 'no relation to other node when tree is undef');
	is( $node2, object {
		call key => 'y';
		call value => 3;
		call count => 0;
		call parent => undef;
		call left   => undef;
		call right  => undef;
		call next   => undef;
		call prev   => undef;
		call older  => undef;
		call newer  => undef;
		call tree   => undef;
		call recent_tracked => F;
	}, 'no relation to other node when tree is undef');
};

subtest as_lol => sub {
	my $t= Tree::RB::XS->new;
	$t->put(a => 1);
	$t->put(b => 2);
	$t->put(c => 3);
	is( $t->root->as_lol,
		[
			[ '*', '*', 'R:a' ],
			[ '*', '*', 'R:c' ],
			'B:b'
		],
		'as_lol returns correct structure'
	);
};

subtest strip => sub {
	my $t= Tree::RB::XS->new;
	$t->put(a => 1);
	$t->put(b => 2);
	$t->put(c => 3);
	my @del;
	$t->root->strip(sub { push @del, $_[0] });
	like( \@del, [ object { call key => 'a'; }, object { call key => 'c'; } ]);
	like( $t->root, object { call key => 'b'; call left => undef; call right => undef; } );
};

subtest node_ownership => sub {
	@canary::dead= ();
	my $tree= Tree::RB::XS->new;
	$tree->put("test1", canary->new("test1"));
	$tree->put("test2", canary->new("test2"));
	my $test1= $tree->root;
	undef $tree;
	is( \@canary::dead, ['test2'], 'free tree frees the remaining node' );
	like( $test1, object {
		call key => 'test1';
		call left => undef;
		call right => undef;
		call left_leaf => undef;
		call right_leaf => undef;
		call tree => undef;
		call parent => undef;
		call prev => undef;
		call next => undef;
		call count => 0;
	}, 'node attributes');
	undef $test1;
	is( \@canary::dead, ['test2','test1'], 'free node frees value' );
};

subtest set_key => sub {
	for my $cmp ( CMP_PERL, CMP_STR, CMP_FOLDCASE ) {
		@canary::dead= ();
		my $t= Tree::RB::XS->new(
			compare_fn => $cmp,
			kv => [ map +($_ => canary->new($_)), qw( a b c d e f g h i j k l m ) ]
		);
		my $node_a= $t->get_node('a');
		my $node_b= $t->get_node('b');
		$node_a->key('a');
		is( [ $t->keys ], [qw( a b c d e f g h i j k l m )], 'keys unchanged' );
		$node_a->key('z');
		is( [ $t->keys ], [qw( b c d e f g h i j k l m z )], 'moved node first to last' );
		$node_a->key('y');
		is( [ $t->keys ], [qw( b c d e f g h i j k l m y )], 'changed node, remain same tree location' );
		$node_a->key('m');
		is( [ $t->keys ], [qw( b c d e f g h i j k l m )], 'change key to clobber m' );
		is( \@canary::dead, ['m'], 'value of node m freed' );
		$node_a->key('b');
		is( $node_a->key, 'b', 'node a has key of b' );
		is( [ $t->keys ], [qw( b c d e f g h i j k l )], 'change key to clobber b' );
		is( \@canary::dead, ['m'], 'value of node b not freed yet' );
		is( $node_b->key, 'b', 'key of node b is still b' );
		is( $node_b->tree, undef, 'key b out of tree' );
		my @remain= qw( c d e f g h i j k l );
		while (@remain) {
			my $k= $remain[0];
			$node_a->key($k);
			is( $node_a->key, $k, "node a has key of $k" );
			is( [ $t->keys ], \@remain, "remaining keys" );
			is( $canary::dead[-1], $k, "value of node $k freed" );
			shift @remain;
		}
	}
};

subtest resize_key => sub {
	# Test code that enlarges the 'extra' buffer of the nodes
	for my $cmp ( CMP_STR, CMP_FOLDCASE ) {
		my $t= Tree::RB::XS->new(compare_fn => $cmp, track_recent => 1);
		$t->put("a");
		$t->put("b");
		$t->put("c");
		# pick a size that almost certainly causes realloc to return a new pointer
		$t->root_node->key("b"x4096);
		is( $t->root_node, object {
			call key => "b"x4096;
			call left => object { call key => 'a'; };
			call right => object { call key => 'c'; };
			call prev => object { call key => 'a'; };
			call next => object { call key => 'c'; };
		}, 'Resized key' );
	}
};

done_testing;
