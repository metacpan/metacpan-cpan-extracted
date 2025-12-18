#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::RealBin/lib";
use Test2WithExplain;
use Tree::RB::XS;
use Time::HiRes 'time';

my $node_cnt= $ENV{TREERBXS_TEST_NODE_COUNT} || 10000;

note "$_=$ENV{$_}" for grep /perl/i, keys %ENV;

for my $cmp (qw( CMP_PERL CMP_INT CMP_FLOAT CMP_MEMCMP CMP_STR CMP_FOLDCASE CMP_NUMSPLIT CMP_NUMSPLIT_FOLDCASE )) {
	subtest $cmp => sub {
		my $tree= Tree::RB::XS->new(compare_fn => Tree::RB::XS->$cmp);
		is( $tree->insert(1 => 1), 0, 'insert, returns index' );
		is( $tree->size, 1, 'size=1' );
		
		my $t0= time;
		for (2..$node_cnt) {
			$tree->insert($_, $_);
		}
		my $t1= time;
		is( $tree->size, $node_cnt, "add $node_cnt nodes" );
		note sprintf("Insert rate = %.0f/sec", int($node_cnt/($t1-$t0))) if $t1 > $t0;
		ok(eval { $tree->_assert_structure; 1 }, 'structure OK' )
			or diag $@;
		undef $tree; # test destructor
	};
}

subtest capture_keys => sub {
	my $tree= Tree::RB::XS->new(key_type => Tree::RB::XS::KEY_TYPE_CLAIM());
	is( $tree->insert(1 => 1), 0, 'insert, returns index' );
	is( $tree->size, 1, 'size=1' );
	
	my $t0= time;
	for (2..$node_cnt) {
		$tree->insert((my $x=$_), $_);
	}
	my $t1= time;
	is( $tree->size, $node_cnt, "add $node_cnt nodes" );
	note sprintf("Insert rate = %.0f/sec", int($node_cnt/($t1-$t0))) if $t1 > $t0;
	ok(eval { $tree->_assert_structure; 1 }, 'structure OK' )
		or diag $@;
	undef $tree; # test destructor
};

subtest custom_tree => sub {
	my $tree= Tree::RB::XS->new(compare_fn => sub { $_[0][0] <=> $_[1][0] });
	is( $tree->insert([1] => 1), 0, 'insert, returns index' );
	is( $tree->size, 1, 'size=1' );
	
	my $t0= time;
	for (2..$node_cnt) {
		$tree->insert([$_], $_);
	}
	my $t1= time;
	is( $tree->size, $node_cnt, "add $node_cnt nodes" );
	note sprintf("Insert rate = %.0f/sec", int($node_cnt/($t1-$t0))) if $t1 > $t0;
	ok(eval { $tree->_assert_structure; 1 }, 'structure OK' )
		or diag $@;
	undef $tree; # test destructor
};

subtest foldcase_tree => sub {
	my $tree= Tree::RB::XS->new(compare_fn => Tree::RB::XS::CMP_FOLDCASE);
	is( $tree->insert_multi(a => 1, B => 1, a => 2, A => 2, b => 3), 2, 'insert multiple conflicting keys' );
	is( [ $tree->keys ], [ 'a', 'B' ], 'only first 2 keys added' );
};

subtest insert_as_node => sub {
	my $tree= Tree::RB::XS->new('foldcase');
	my $node1= $tree->insert_as_node(AA => 1);
	my $node2= $tree->insert_as_node(Aa => 2);
	my $node3= $tree->insert_as_node(aa => 3);
	is( $node2, undef, "didn't add conflicting key" );
	is( $node3, undef, "didn't add conflicting key" );
	$tree->allow_duplicates(1);
	$node2= $tree->insert_as_node(aa => 2);
	$node3= $tree->insert_as_node(Aa => 3);
	is( [$tree->keys], ['AA','aa','Aa'], 'have duplicates' );
	is( $node1->key, 'AA', 'node1 key' );
	is( $node2->key, 'aa', 'node2 key' );
	is( $node3->key, 'Aa', 'node3 key' );
	my $node4= $tree->put_as_node('aA');
	is( [$tree->keys], ['aA'], 'replaced all nodes' );
	ok( $node4 == $node1, 're-used node1' );
	is( $tree->size, 1, 'put replaced all nodes' );
	ok( !$node2->tree, 'node2 pruned' );
	ok( !$node3->tree, 'node3 pruned' );
	is( $node1->key, 'aA', 'preserved most recent original key' );
};

done_testing;
