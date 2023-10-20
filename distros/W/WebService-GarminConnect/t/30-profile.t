#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Data::Dumper;
use WebService::GarminConnect;

# This test connects to Garmin Connect, so it will only run if
# GARMIN_USERNAME and GARMIN_PASSWORD are set in the environment.
#
# If you run this test, this account must have at least 7 activities.
#
if (!defined $ENV{GARMIN_USERNAME} &&
    !defined $ENV{GARMIN_PASSWORD} ) {
  plan skip_all => 'set GARMIN_{USERNAME,PASSWORD} to run network tests';
} else {
  plan tests => 5;
}

my $gc = WebService::GarminConnect->new(
  username => $ENV{GARMIN_USERNAME},
  password => $ENV{GARMIN_PASSWORD},
);
isnt($gc, undef, "create instance");

# Try to login. If this works, the 'is_logged_in' key should
# be defined afterward.
$gc->_login();
ok(defined $gc->{is_logged_in}, "login succeeded");

my $profile;
ok($profile = $gc->profile, "profile obtained");
ok(exists $profile->{userName}, "profile has a userName");
is($profile->{userName}, $ENV{GARMIN_USERNAME}, "userName matches");
