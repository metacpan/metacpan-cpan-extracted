#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";

use Modern::Perl;

use Test::Most tests => 1;

use Test::Harness::KS;

use Log::Log4perl ':easy';
Log::Log4perl->easy_init($TRACE);



subtest "Scenario: Test user-defined test files normalization", sub {
  plan tests => 1;

  my $files = Test::Harness::KS::parseOtherTests([
    'fun.t fun.t, function.t',
    'test/more/files.t',
    'this.t output.t
    is.t from.t
    ls.t.from.gnu'
  ]);
  my $expectedFiles = [
    qw(fun.t fun.t function.t test/more/files.t this.t output.t is.t from.t ls.t.from.gnu)
  ];
  eq_or_diff($files, $expectedFiles);
};



done_testing;
