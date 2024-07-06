#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::RealBin/lib";
use Test2WithExplain;
use Tree::RB::XS;
use Time::HiRes 'time';

subtest basic_insertion_order => sub {
   my $t= Tree::RB::XS->new(track_recent => 1);
   is( $t->oldest, undef, 'oldest of empty tree' );
   is( $t->newest, undef, 'newest of empty tree' );
   $t->put(1,1);
   $t->put(2,2);
   $t->put(0,0);
   is( $t->oldest->key, 1, 'oldest' );
   is( $t->newest->key, 0, 'newest' );
   is( $t->recent_count, 3, 'recent_count' );
   is( $t->oldest->newer->key, 2, 'oldest->newer' );
   is( $t->newest->older->key, 2, 'newest->older' );
};

subtest re_insert => sub {
   my $t= Tree::RB::XS->new(track_recent => 1);
   $t->put(1,1);
   $t->put(2,2);
   $t->put(1,1);
   is( $t->oldest->key, 2, 'oldest' );
   is( $t->newest->key, 1, 'newest' );
   is( $t->recent_count, 2, 'recent_count' );
   is( $t->oldest->newer->key, 1, 'oldest->newer' );
   is( $t->newest->older->key, 2, 'newest->older' );

   $t->put(6,6);
   is( $t->newest->key, 6, 'newest = 6' );
   # insert node 6 following node 2
   $t->get_node(2)->newer($t->get_node(6));
   is( $t->newest->key, 1, 'newest = 1' );
   is( $t->newest->older->key, 6, '6 at middle' );
   # insert node 1 before node 6
   $t->get_node(6)->older($t->get_node(1));
   is( $t->newest->key, 6, 'newest = 6' );
   is( $t->newest->older->key, 1, '1 at middle' );

   is( $t->newest($t->get_node(1))->key, 1, 'newest = 1' );
   is( $t->oldest($t->get_node(1))->key, 1, 'oldest = 1' );
   
   $t->lookup_updates_recent(1);
   my $n= $t->get_node(6);
   is( $t->newest, $n, 'accessing 6 makes it the newest' );
};

subtest delete => sub {
   my $t= Tree::RB::XS->new(track_recent => 1);
   is( $t->oldest, undef, 'oldest' );
   is( $t->newest, undef, 'newest' );
   $t->put(1,1); note( 'put(1,1)' );
   is( $t->oldest->key, 1, 'oldest' );
   is( $t->newest->key, 1, 'newest' );
   ok( $t->delete(1), 'delete(1)' );
   is( $t->recent_count, 0, 'recent_count' );
   is( $t->oldest, undef, 'oldest' );
   is( $t->newest, undef, 'newest' );
   
   $t->put(1,1); note( 'put(1,1)' );
   $t->put(2,2); note( 'put(2,2)' );
   $t->put(3,3); note( 'put(3,3)' );
   $t->put(4,4); note( 'put(4,4)' );
   is( $t->recent_count, 4, 'recent_count = 4' );
   ok( $t->delete(2), 'delete(2)' );
   is( $t->oldest->newer->key, 3, 'oldest->newer' );
   is( $t->newest->older->key, 3, 'newest->older' );
   ok( $t->delete(4), 'delete(4)' );
   is( $t->oldest->newer->key, 3, 'oldest->newer' );
   is( $t->newest->older->key, 1, 'newest->older' );
   ok( $t->delete(1), 'delete(1)' );
   is( $t->oldest->key, 3, 'oldest->newer' );
   is( $t->newest->key, 3, 'newest->older' );
   ok( $t->delete(3), 'delete(3)' );
   is( $t->oldest, undef, 'oldest = null' );
   is( $t->newest, undef, 'newest = null' );
};

subtest iterators => sub {
   my $t= Tree::RB::XS->new(track_recent => 1);
   $t->put(1,1); note 'put(1,1)';
   $t->put(2,2); note 'put(2,2)';
   $t->put(3,3); note 'put(3,3)';
   $t->put(4,4); note 'put(4,4)';
   is( $t->recent_count, 4, 'recent_count = 4' );
   is( [$t->iter_newer->next_keys('*')], [1,2,3,4], 'iter_old_to_new' );
   is( [$t->iter_older->next_keys(9**9**9)], [4,3,2,1], 'iter_new_to_old' );
   $t->delete(2); note 'delete(2)';
   is( $t->recent_count, 3, 'recent_count = 3' );
   is( [$t->iter_newer->next_keys(1e90)], [1,3,4], 'iter_old_to_new' );
   is( [$t->iter_older->next_keys('*')], [4,3,1], 'iter_new_to_old' );
   $t->put(2,2); note 'put(2,2)';
   is( $t->recent_count, 4, 'recent_count = 4' );
   is( [$t->iter_newer->next_keys('*')], [1,3,4,2], 'iter_old_to_new' );
   is( [$t->iter_older->next_keys('*')], [2,4,3,1], 'iter_new_to_old' );
   is( [$t->oldest->iter_newer->next_keys('*')], [1,3,4,2], 'oldest->iter_newer' );
   is( [$t->newest->iter_older->next_keys('*')], [2,4,3,1], 'newest->iter_older' );
   my $iter= $t->iter_newer;
   is( $iter->next_key, 1, 'iter->next_key' );
   is( $iter->next_key, 3, 'iter->next_key' );
   ok( $iter->step(-1), 'iter->step(-1)' );
   is( $iter->next_key, 3, 'iter->next_key' );
   $iter= $t->iter_newer;
   is( $iter->key, 1, 'recent[0] == 1' );
   my $iter2= $t->iter_newer; $iter2->step(1);
   is( $iter2->key, 3, 'recent[1] == 3' );
   my $iter3= $t->iter_older; $iter3->step(1);
   is( $iter3->key, 4, 'recent[-1] == 4' );
   my $iter4= $t->iter_newer; $iter4->step(3);
   is( $iter4->key, 2, 'recent[3] == 1' );
   my $iterA= $t->iter;
   my $iterB= $t->iter; $iterB->step(1);
   my $iterC= $t->iter; $iterC->step(2);
   my $iterD= $t->iter; $iterD->step(3);
   
   # delete or un-track nodes, and verify iterators bump to correct destination
   $t->get_node(4)->recent_tracked(0);
   is( $t->get_node(4)->newer, undef, 'untracked ->newer' );
   is( $t->get_node(4)->older, undef, 'untracked ->older' );
   is( $iter3->key, 3, 'rev iter bumped backward' );
   is( $iterD->key, 4, 'normal iter still on 4' );
   $t->delete(3);
   is( $iterC->key, 4, 'forward normal iter goes to 4' );
   is( $iter3->key, 1, 'rev recent iter bumped backward' );
   ok( $iter2->key, 2, 'forward recent iter bumped forward' );
   $t->delete(1);
   is( $iterA->key, 2, 'forward normal iter bumped forward' );
   is( $iter->key, 2, 'forward recent iter bumped forward' );
   ok( $iter3->done, 'reverse recent iter bumped off end' );
   ok( $iter->node == $iter2->node && $iter2->node == $iter4->node, 'iters stacked on final' );
   $t->get_node(4)->mark_newest;
   $t->get_node(2)->recent_tracked(0);
   ok( $iterA->node == $iterB->node && $iterB->key == 2, 'normal iters still on node 2' );
   is( $iter->key, 4, 'recent iters bumped to new newest node' );
   ok( $iter->node == $iter2->node && $iter2->node == $iter4->node, 'iters stacked on new final' );
   ok( !$iter->step(1), 'step iter1 reaches end' );
   &$iter2;
   ok( $iter2->done, 'iter2 reached end' );

   $t->clear;
   for ($iter, $iter2, $iter3, $iter4, $iterA, $iterB, $iterC, $iterD) {
      is( $iter, object {
         call key => undef;
         call value => undef;
         call node => undef;
         call done => T;
         call next => undef;
      });
   }
};

done_testing;
