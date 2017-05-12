#!perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}


use 5.010;
use strict;
use warnings;

use Test::More 0.98;
use Test::WithDB;

my $twdb = Test::WithDB->new(config_profile=>'twdb-test-Pg');
my $dbh = $twdb->create_db;
ok($dbh);
undef $twdb;

DONE_TESTING:
done_testing;
