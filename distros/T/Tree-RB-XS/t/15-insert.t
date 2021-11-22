#!/usr/bin/env perl
use Test2::V0;
use Tree::RB::XS;
use Time::HiRes 'time';

my $node_cnt= $ENV{TREERBXS_TEST_NODE_COUNT} || 10000;

note "$_=$ENV{$_}" for grep /perl/i, keys %ENV;

for my $type (qw( KEY_TYPE_ANY KEY_TYPE_INT KEY_TYPE_FLOAT KEY_TYPE_BSTR KEY_TYPE_USTR )) {
	subtest $type => sub {
		my $tree= Tree::RB::XS->new(key_type => Tree::RB::XS->$type);
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

done_testing;
