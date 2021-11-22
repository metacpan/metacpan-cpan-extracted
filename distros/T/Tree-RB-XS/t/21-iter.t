#!/usr/bin/env perl
use Test2::V0;
use Tree::RB::XS;
use Time::HiRes 'time';
use Scalar::Util 'weaken';

subtest iterate_gap => sub {
	my $tree= Tree::RB::XS->new(key_type => 'int');
	weaken(my $tref= $tree);
	$tree->put($_ => $_) for 0, 1, 2, 4;
	is( $tree->iter->next->value, 0, 'left = 0' );
	is( $tree->iter(2)->next->value, 2, 'at(2) = 2' );
	is( $tree->iter(3)->next->value, 4, 'at(3) = 4' );
	is( $tree->rev_iter(1)->next->value, 1, 'rev at(1) = 1' );
	is( $tree->rev_iter(3)->next->value, 2, 'rev at(3) = 2' );
	++$_ for $tree->iter(2)->value;
	is( $tree->iter(2)->next->value, 3 );
	undef $tree;
	is( $tref, undef, 'tree freed' );
};

subtest iterate_dups => sub {
	my $tree= Tree::RB::XS->new(key_type => 'int');
	weaken(my $tref= $tree);
	$tree->allow_duplicates(1);
	$tree->insert(2, 2);
	$tree->insert(2, '2a');
	$tree->insert(2, '2b');
	my @vals;
	my $i;
	for ($i= $tree->iter(2); !$i->done; $i->step) {
		push @vals, $i->value;
	}
	is( \@vals, [2,'2a','2b'], 'iterate key=2' );

	@vals= ();
	for ($i= $tree->rev_iter(2); !$i->done; $i->step) {
		push @vals, $i->value;
	}
	is( \@vals, ['2b','2a',2], 'reverse iterate key=2' );
	undef $tree;
	undef $i;
	is( $tref, undef, 'tree freed' );
};

subtest iterate_skip => sub {
	my $tree= Tree::RB::XS->new(key_type => 'int');
	weaken(my $tref= $tree);
	$tree->put($_ => $_) for 0..10;
	my (@vals, $i);
	for ($i= $tree->iter; !$i->done; $i->step(2)) {
		push @vals, $i->value;
	}
	is( \@vals, [0,2,4,6,8,10], 'step by 2' );
	@vals= ();
	for ($i= $tree->rev_iter; !$i->done; $i->step(2)) {
		push @vals, $i->value;
	}
	is( \@vals, [10,8,6,4,2,0], 'rev by 2' );
	@vals= ();

	$i= $tree->max_node->iter;
	$i->step;
	ok( $i->done, 'at end,' );
	ok( $i->step(-3), 'back up 3' );
	is( $i->value, 8, 'at 8' );
	
	$i= $tree->min_node->rev_iter;
	$i->step;
	ok( $i->done, 'at end,' );
	ok( $i->step(-3), 'back up 3' );
	is( $i->value, 2, 'at 2' );

	undef $tree;
	undef $i;
	is( $tref, undef, 'tree freed' );
};

subtest iterate_rewind => sub {
	my $tree= Tree::RB::XS->new(key_type => 'int');
	weaken(my $tref= $tree);
	$tree->put($_ => $_) for 0..10;
	my $i= $tree->iter;
	while ($i->step) {}
	ok( $i->done, 'done' );
	is( $i->key, undef, 'key is undef at end' );
	is( $i->value, undef, 'value is undef at end' );
	is( $i->index, undef, 'index is undef at end' );
	
	ok( $i->step(-1), 'back to max element' );
	is( $i->value, 10, 'final=10' );

	$i= $tree->rev_iter;
	while ($i->step) {}
	ok( $i->done, 'done' );
	is( $i->key, undef, 'key is undef at end' );
	is( $i->value, undef, 'value is undef at end' );
	
	ok( $i->step(-1), 'back to min element' );
	is( $i->value, 0, 'min=0' );

	undef $tree;
	ok( $tref, 'tree not freed' );
	$i->step;
	ok( $tref, 'tree not freed' );
	undef $i;
	is( $tref, undef, 'tree freed' );
};

subtest iterate_chaos_with_deletions => sub {
	my $tree= Tree::RB::XS->new(key_type => 'int');
	weaken(my $tref= $tree);
	$tree->put($_ => $_) for 0..10;

	my @iter= ( map($tree->iter, 1..100), map($tree->rev_iter, 1..100) );
	is( scalar @iter, 200, 'create 200 iterators' );
	my @iter_refs= @iter;
	weaken($_) for @iter_refs;

	while (@iter > 75) {
		my $i= int rand scalar @iter;
		if (!$iter[$i]->step(1 + int rand 2)) {
			splice(@iter, $i, 1);
		}
	}
	note '75 left';
	$tree->delete(4);
	$tree->delete(5);
	$tree->delete(6);
	while (@iter > 50) {
		my $i= int rand scalar @iter;
		if (!$iter[$i]->step(1 + int rand 2)) {
			splice(@iter, $i, 1);
		}
	}
	note '50 left';
	$tree->delete(0);
	$tree->delete(1);
	$tree->delete(9);
	$tree->delete(10);
	while (@iter) {
		my $i= int rand scalar @iter;
		if (!$iter[$i]->step(1 + int rand 2)) {
			splice(@iter, $i, 1);
		}
	}
	note 'all finished';
	is( \@iter_refs, [ (undef)x200 ], 'all iters freed' );
	undef $tree;
	is( $tref, undef, 'tree freed' );
};

subtest iter_get_multi => sub {
	my $tree= Tree::RB::XS->new(key_type => 'int');
	weaken(my $tref= $tree);
	$tree->put($_ => $_*2) for 0..20;
	is( [ $tree->nth(15)->iter->next_keys('*') ], [ 15, 16, 17, 18, 19, 20 ], 'next_keys(*)' );
	is( [ $tree->nth(20)->iter->next_keys(10) ], [ 20 ], 'next_keys overshoot' );
	is( [ $tree->rev_iter(4)->next_keys(50) ], [ 4, 3, 2, 1, 0 ], 'reverse next_keys overshoot' );
	is( [ $tree->rev_iter(1)->next_keys(1) ], [ 1 ], 'reverse next_keys for 1' );
	is( [ $tree->iter->next_keys(0) ], [], 'iterate nothing' );
	is( [ $tree->iter->next_values(4) ], [ 0, 2, 4, 6 ], 'next_values(4)' );
	is( [ $tree->iter->next(2) ], [
		object{ call key => 0; call value => 0; etc; },
		object{ call key => 1; call value => 2; etc; },
	], 'next_nodes(2)' );
	is( [ $tree->iter(1)->next_kv(2) ], [ 1, 2, 2, 4 ], 'next_kv' );
	++$_ for $tree->iter->next_values('*');
	is( $tree->nth(10)->value, 21, 'modified value' );
	undef $tree;
	is( $tref, undef, 'tree freed' );
};

subtest iter_delete => sub {
	my $tree= Tree::RB::XS->new;
	weaken(my $tref= $tree);
	$tree->put($_ => $_) for qw( 1 2 3 4 5 6 7 8 9 );
	my $i;
	for ($i= $tree->iter; !$i->done;) {
		if ($i->key & 1) {
			my $k= $i->key;
			is( $i->delete, $k, "delete $k" );
		} else {
			$i->step;
		}
	}
	is( [$tree->iter->next_keys('*')], [2,4,6,8], 'even numbers remaining' );
	undef $i;
	undef $tree;
	is( $tref, undef, 'tree freed' );
};

done_testing;
