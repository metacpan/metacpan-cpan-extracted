#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Builder::Tester;

use Test::Metrics::Any;

use Metrics::Any '$metrics';

$metrics->make_counter( metric =>
   name => "the_metric_name",
);

# OK
{
   test_out( "ok 1 - metric OK" );
   is_metrics_from(
      sub { $metrics->inc_counter( metric => ); },
      { the_metric_name => 1 },
      'metric OK'
   );
   test_test( "metric OK succeeds" );
}

# Missing
{
   test_out( "not ok 1 - metric missing" );
   test_fail( +4 );
   test_err( "# Expected a metric called 'a_different_metric' but didn't find one" );
   is_metrics_from(
      sub { $metrics->inc_counter( metric => ); },
      { a_different_metric => 1 },
      'metric missing'
   );
   test_test( "metric missing fails" );
}

# Wrong value
{
   test_out( "not ok 1 - metric differing" );
   test_fail( +4 );
   test_err( "# Expected metric 'the_metric_name' to be 2 but got 4" );
   is_metrics_from(
      sub { $metrics->inc_counter_by( metric => 4 ); },
      { the_metric_name => 2 },
      'metric differing'
   );
   test_test( "metric differing fails" );
}

done_testing;
