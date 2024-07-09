#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::RealBin/lib";
use Test2WithExplain;
use Tree::RB::XS qw( KEY_TYPE_BSTR :get :cmp );
use Time::HiRes 'time';

my $node_cnt= $ENV{TREERBXS_TEST_NODE_COUNT} || 100000;

subtest int_tree => sub {
	my $tree= Tree::RB::XS->new(compare_fn => CMP_INT);
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
	my $tree= Tree::RB::XS->new(compare_fn => CMP_FLOAT);
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
	my $tree= Tree::RB::XS->new(compare_fn => CMP_MEMCMP);
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
	my $tree= Tree::RB::XS->new(compare_fn => sub { $_[0][0] <=> $_[1][0] });
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

subtest get_key => sub {
	my $tree= Tree::RB::XS->new(kv => [ a => 1, b => 2, c => 3 ]);
	is( $tree->get_key('b', GET_GT), 'c', 'key >  "b" is "c"' );
	is( $tree->get_key_gt('b'),      'c', 'key >  "b" is "c"' );
	is( $tree->get_key_ge('b'),      'b', 'key >= "b" is "b"' );
	is( $tree->get_key_lt('f'),      'c', 'key <  "f" is "c"' );
	is( $tree->get_key_le('b'),      'b', 'key <= "b" is "b"' );
};

subtest get_all => sub {
	my $tree= Tree::RB::XS->new;
	$tree->allow_duplicates(1);
	$tree->insert($_ => $_) for 1..20;
	$tree->insert(5 => 'X'.(5-$_)) for 0..4;
	is( [ $tree->get_all(5) ], [qw( 5 X5 X4 X3 X2 X1 )], 'all values, in insertion order' );
};

subtest get_or_add => sub {
	my $tree= Tree::RB::XS->new;
	{ no warnings 'uninitialized';
		$_ .= "example" for $tree->get("b", GET_OR_ADD);
		++$_ for $tree->get("a", GET_OR_ADD);
		($_ ||= 5) for $tree->get("a", GET_OR_ADD);
		is( [$tree->iter->next_kv('*')], [ a => 1, b => "example" ] );
	}

	# again with actual lval syntax
	$tree= Tree::RB::XS->new;
	{ no warnings 'uninitialized';
		$tree->get("b", GET_OR_ADD) .= "example";
		++$tree->get("a", GET_OR_ADD);
	}
	is( [$tree->iter->next_kv('*')], [ a => 1, b => "example" ] );

	# again with alias method 'get_or_add'
	$tree= Tree::RB::XS->new;
	{ no warnings 'uninitialized';
		$tree->get_or_add("b") .= "example";
		$tree->get_or_add("a")++;
	}
	is( [$tree->iter->next_kv('*')], [ a => 1, b => "example" ] );
};

done_testing;
