#!/usr/bin/perl

use v5.20;
use warnings;

use Test2::V0;
use Test::Builder::Tester;

use Test::Metrics::Any;

use Metrics::Any '$metrics';

# Detect the line number reporting behaviour of this version of perl, to
# defend against failures introduced by Perl #24396
my $CALLER_SEES_BLOCK_END;
BEGIN {
   sub probe_caller {
      my $line = (caller)[2];
      $CALLER_SEES_BLOCK_END = 1 if $line != shift;
   }
   probe_caller __LINE__,
      sub { };
}

$metrics->make_counter( metric =>
   name => "the_metric_name",
);

# positive
{
   test_out( "ok 1 - positive" );
   is_metrics_from(
      sub { $metrics->inc_counter( metric => ); },
      { the_metric_name => Test::Metrics::Any::positive },
      'positive'
   );
   test_test( "positive OK succeeds" );

   test_out( "not ok 1 - positive" );
   test_fail( $CALLER_SEES_BLOCK_END ? +4 : +2 );
   test_err( "# Expected metric 'the_metric_name' to be positive but got 0" );
   is_metrics_from(
      sub { $metrics->inc_counter_by( metric => 0 ); },
      { the_metric_name => Test::Metrics::Any::positive },
      'positive'
   );
   test_test( "positive not ok fails" );
}

# at_least
{
   test_out( "ok 1 - at_least" );
   is_metrics_from(
      sub { $metrics->inc_counter_by( metric => 5 ); },
      { the_metric_name => Test::Metrics::Any::at_least(3) },
      'at_least'
   );
   test_test( "at_least OK succeeds" );

   test_out( "not ok 1 - at_least" );
   test_fail( $CALLER_SEES_BLOCK_END ? +4 : +2 );
   test_err( "# Expected metric 'the_metric_name' to be at least 3 but got 2" );
   is_metrics_from(
      sub { $metrics->inc_counter_by( metric => 2 ); },
      { the_metric_name => Test::Metrics::Any::at_least(3) },
      'at_least'
   );
   test_test( "at_least not ok fails" );
}

# greater_than
{
   test_out( "ok 1 - greater_than" );
   is_metrics_from(
      sub { $metrics->inc_counter_by( metric => 5 ); },
      { the_metric_name => Test::Metrics::Any::greater_than(3) },
      'greater_than'
   );
   test_test( "greater_than OK succeeds" );

   test_out( "not ok 1 - greater_than" );
   test_fail( $CALLER_SEES_BLOCK_END ? +4 : +2 );
   test_err( "# Expected metric 'the_metric_name' to be greater than 3 but got 3" );
   is_metrics_from(
      sub { $metrics->inc_counter_by( metric => 3 ); },
      { the_metric_name => Test::Metrics::Any::greater_than(3) },
      'greater_than'
   );
   test_test( "greater_than not ok fails" );
}

done_testing;
