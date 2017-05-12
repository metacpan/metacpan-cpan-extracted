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
  plan tests => 11;
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

# Retrieve one activity. This assumes the Germin Connect account
# we're using has at least one activity.
my @activities = $gc->activities( limit => 1 );
is(scalar @activities, 1, "limit of 1 returns 1 activity");
my $a = $activities[0];
ok(defined $a->{activity}, "top-level activity key defined");
# Check some of the keys that all activities should have.
foreach my $key ( qw( activityName username activityType beginTimestamp
                      sumDistance ) ) {
  ok(defined $a->{activity}->{$key}, "activity has key $key");
}

# Use a small page size, and test retrieving more activities
# than fit in the first page.
@activities = $gc->activities( limit => 7, pagesize => 5 );
is(scalar @activities, 7, "limit of 7 returns 7 activities");

# Retrieve with no limit, and make sure we get back all the user's
# activities.
my $total = $gc->{total_activities};
@activities = $gc->activities();
is(scalar @activities, $total, "no limit returns all $total activities");
