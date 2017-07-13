#!perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}


use 5.010;
use strict;
use warnings;

use Test::More 0.98;
use Test::WithDB;

my $twdb = Test::WithDB->new(config_profile=>'twdb-test-SQLite');
my $dbh = $twdb->create_db;
ok($dbh);
undef $twdb;

DONE_TESTING:
done_testing;
