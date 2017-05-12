#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
  use_ok q{Test::FITesque}, qw(run_tests suite test);
}

use lib 't/mock';
use Test::FakeBuilder;
$Test::FITesque::Test::TEST_BUILDER  = Test::FakeBuilder->new();
$Test::FITesque::Suite::TEST_BUILDER = Test::FakeBuilder->new();

use lib 't/lib';

Basic_usage: {
  run_tests {
    suite {
      test {
        [q{Buddha::FITesqueFixture}],
        [q{one}],
      },
      test {
        [q{Buddha::FITesqueFixture}],
        [q{two}],
      },
    },
    test {
      [q{Buddha::FITesqueFixture}],
      [q{three}],
    }
  };

  is_deeply $Buddha::FITesqueFixture::RECORDED, [qw{one two three}], q{Helper functions work};
}

Single_use: {
  $Buddha::FITesqueFixture::RECORDED = [];
  run_tests {
    test {
      [q{Buddha::FITesqueFixture}],
      [q{one}],
      [q{three}],
      [q{two}],
    }
  };
  
  is_deeply $Buddha::FITesqueFixture::RECORDED, [qw(one three two)], q{Single one};
}
