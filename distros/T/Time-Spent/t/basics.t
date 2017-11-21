use strict;
use warnings;
use Test::More;
use Test::TinyMocker;
use Guard qw( scope_guard );

my $class = 'Time::Spent';

use_ok $class;

subtest basics => sub {
  my @times = ( ( 0, 5 ), ( 5, 15 ), ( 15, 30 ), ( 30, 50 ) );
  mock $class => method 'ts' => should { shift @times };
  scope_guard { unmock $class => methods [ 'ts' ] };

  my $length  = 3;
  my $tracker = new_ok $class, [ length => $length ];
  ok !defined $tracker->avg, 'initial avg is 0';

  ok !$tracker->is_tracking( 'a' ), '!is_tracking a';
  is $tracker->start( 'a' ), 1, 'start a';
  ok $tracker->is_tracking( 'a' ), 'is_tracking a';
  is $tracker->stop( 'a' ), 1, 'stop a';
  ok !$tracker->is_tracking( 'a' ), '!is_tracking a';
  cmp_ok $tracker->avg, '==', 5, 'avg a';

  ok !$tracker->is_tracking( 'b' ), '!is_tracking b';
  is $tracker->start( 'b' ), 1, 'start b';
  ok $tracker->is_tracking( 'b' ), 'is_tracking b';
  is $tracker->stop( 'b' ), 1, 'stop b';
  ok !$tracker->is_tracking( 'b' ), '!is_tracking b';
  cmp_ok $tracker->avg, '==', 7.5, 'avg b';

  ok !$tracker->is_tracking( 'c' ), '!is_tracking c';
  is $tracker->start( 'c' ), 1, 'start c';
  ok $tracker->is_tracking( 'c' ), 'is_tracking c';
  is $tracker->stop( 'c' ), 1, 'stop c';
  ok !$tracker->is_tracking( 'c' ), '!is_tracking c';
  cmp_ok $tracker->avg, '==', 10, 'avg c';

  ok !$tracker->is_tracking( 'd' ), '!is_tracking d';
  is $tracker->start( 'd' ), 1, 'start d';
  ok $tracker->is_tracking( 'd' ), 'is_tracking d';
  is $tracker->stop( 'd' ), 1, 'stop d';
  ok !$tracker->is_tracking( 'd' ), '!is_tracking d';
  cmp_ok $tracker->avg, '==', 15, 'avg d';
};

subtest new => sub {
  eval { $class->new };
  ok $@, 'new() fail without length';

  eval { $class->new( length => 0 ) };
  ok $@, 'new() fail with length == 0';

  eval { $class->new( length => -10 ) };
  ok $@, 'new() fail with length < 0';

  eval { $class->new( length => 'a' ) };
  ok $@, 'new() fail with non-integer length';
};

subtest start => sub {
  my $tracker = new_ok $class, [ length => 1 ];

  eval { $tracker->start };
  ok $@, 'fail without identifier';

  is_deeply [ $tracker->start( qw( a b c ) ) ], [ qw( a b c ) ], 'list context';

  eval { $tracker->start( 'a' ) };
  ok $@, 'fail with existing identifier';
};

subtest stop => sub {
  my $tracker = new_ok $class, [ length => 1 ];

  eval { $tracker->stop };
  ok $@, 'fail without identifier';

  eval { $tracker->stop( 'a' ) };
  ok $@, 'fail with untracked identifier';
};

done_testing;

