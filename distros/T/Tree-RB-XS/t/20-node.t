#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::RealBin/lib";
use Test2WithExplain;
use Tree::RB::XS qw( KEY_TYPE_INT KEY_TYPE_FLOAT KEY_TYPE_USTR KEY_TYPE_BSTR KEY_TYPE_ANY );
use Time::HiRes 'time';

my $tree= Tree::RB::XS->new(key_type => KEY_TYPE_INT);
$tree->put(1 => 2);
my $node= $tree->min_node;
is( $node->key,    1,     'key'    );
is( $node->value,  2,     'value'  );
is( $node->count,  1,     'count'  );
is( $node->color,  0,     'color'  );
is( $node->parent, undef, 'parent' );
is( $node->left,   undef, 'left'   );
is( $node->right,  undef, 'right'  );
is( $node->next,   undef, 'next'   );
is( $node->prev,   undef, 'prev'   );

is( $tree->max_node,     $node, 'max node same as min' );
is( $tree->nth_node(0),  $node, 'index up from 0' );
is( $tree->nth_node(-1), $node, 'index down from size' );
is( $tree->nth_node(1),  undef, 'no node 1' );

for (1..9) { $tree->put($_ => $_); }
for (2..9) { is( ($node= $node->next)->value, $_, "next -> $_" ) }
is( $node->next, undef, 'end' );

is( $tree->nth_node(5)->value, 6, 'nth(5)' );

# Ensure the 'key' accessor can read all types of keys
for (KEY_TYPE_ANY, KEY_TYPE_INT, KEY_TYPE_FLOAT, KEY_TYPE_USTR, KEY_TYPE_BSTR) {
	$tree= Tree::RB::XS->new(key_type => $_);
	$tree->put(42 => 1);
	is( $tree->min_node->key, 42, "key from type $_" );
}

$tree->put(x => 2);
is( $tree->size, 2, '2 nodes before prune' );
ok( my $x= $tree->get_node('x') );
is( $x->prev, $tree->max_node, 'has next' );
is( $x->prune, 1, 'remove "x"' );
is( $x->prev, undef, 'no longer has next' );
is( $x->prune, 0, 'already removed' );
is( $tree->size, 1, '1 node after prune' );
is( $tree->min->key, 42 );
is( $tree->min->prune, 1, 'remove last node' );
is( $tree->size, 0, 'tree empty' );

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
	my $tree= Tree::RB::XS->new;
	{ package canary;
	  our @dead;
	  sub new { my $x= $_[1]; bless \$x, $_[0] }
	  sub DESTROY { push @dead, ${$_[0]} }
	}
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

done_testing;
