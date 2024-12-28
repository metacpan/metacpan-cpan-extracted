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

done_testing;
