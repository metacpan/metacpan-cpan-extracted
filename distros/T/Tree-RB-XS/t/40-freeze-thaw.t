#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::RealBin/lib";
use Test2WithExplain;
use Tree::RB::XS qw/ :key_type :cmp /;
use Time::HiRes 'time';
use Storable qw( freeze thaw dclone );

subtest preserve_state => sub {
   # create the most convoluted state I can think of for a tree
   my @keys= qw( a h e y i o p w z y q b m n a a d s a l k j h g f t r e w c q );

   my $tree= Tree::RB::XS->new(allow_duplicates => 1, track_recent => 1);

   $tree->insert($keys[$_], $_) for 0..$#keys;

   $tree->allow_duplicates(0); # doesn't remove existing duplicates, but this broken state needs preserved

   # remove several nodes from recent-tracking
   $tree->nth($_)->recent_tracked(0) for reverse 1, 6, 9, 10, 13, 14, 15, 20;
   $tree->get_node('a')->mark_newest; # puts collection of 'a' nodes out of order

   # Serialize it
   my $buffer= freeze $tree;
   my $tree2= thaw $buffer;

   # check attributes
   is( $tree2, object {
      call compare_fn            => $tree->compare_fn;
      call allow_duplicates      => $tree->allow_duplicates;
      call track_recent          => $tree->track_recent;
      call compat_list_get       => $tree->compat_list_get;
      call lookup_updates_recent => $tree->lookup_updates_recent;
      call size                  => $tree->size;
      call recent_count          => $tree->recent_count;
   }, 'tree2 attributes' );

   # compare keys
   my @expect= $tree->iter->next_kv(9e9);
   my @actual= $tree2->iter->next_kv(9e9);
   is( \@actual, \@expect, 'key/value order' );

   # compare recent-order
   @expect= $tree->iter_newer->next_kv(9e9);
   @actual= $tree2->iter_newer->next_kv(9e9);
   is( \@actual, \@expect, 'recent order' );
};

sub compare_it { $_[1] <=> $_[0] }

subtest dclone => sub {
   # Test ability to clone a tree with custom compare function
   my $tree= Tree::RB::XS->new(compare_fn => sub { $_[1] <=> $_[0] });
   my $tree2= eval { dclone($tree) };
   is( $tree2, undef, 'dclone failed for anon coderef' );

   $tree= Tree::RB::XS->new(compare_fn => \&compare_it);
   $tree2= eval { dclone($tree) };
   is( $tree2, object { call compare_fn => \&compare_it; }, 'dclone succeeds for global sub' );
   
   # Now try serializing with node objects
   $tree= Tree::RB::XS->new(kv => [ 1,2, 3,4, 5,6, 7,8 ]);
   my $node_34= $tree->get_node(3);
   my $node_78= $tree->get_node(7);
   my $node_56= $tree->get_node(5);
   $node_56->prune;
   my $buffer= freeze [ $node_34, $node_78, $node_56 ];
   my ($new_34, $new_78, $new_56)= @{ thaw $buffer };
   is( $new_34, object {
      call key   => 3;
      call value => 4;
   }, 'deserialized node (3,4)' );
   is( $new_78, object {
      call key   => 7;
      call value => 8;
      call tree  => $new_34->tree;
   }, 'deserialized node (7,8)' );
   is( $new_56, object {
      call key   => 5;
      call value => 6;
      call tree  => undef;
   }, 'deserialized disconnected node (5,6)' );
   
   # Now try serializing iterators
   todo "Storable is unable to serialize coderefs, even if freeze/thaw are defined" => sub {
      my $iter_clone= eval {
         $buffer= freeze $tree->iter;
         thaw $buffer;
      };
      is( $iter_clone, object { call next_key => $tree->min_node->key; });
   };
};

done_testing;
