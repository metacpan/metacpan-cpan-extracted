#!/usr/bin/perl -w
use 5.010;
use strict;
use warnings;
use Test::More;
use WebService::Beeminder;

my $TEST_GOAL = 'test';

if (not $ENV{AUTHOR_TESTING} ) {
    plan skip_all => 'Set $ENV{AUTHOR_TESTING} to run author tests.'
}

my $token_file = "$ENV{HOME}/.webservice-beeminder.token";
my $token;

eval {
    open(my $fh, '<', $token_file);
    chomp($token = <$fh>);
};

if (not $token) {
    plan skip_all => "Cannot read $token_file";
}

# Retrieving data points can be done both with and without a dry-run,
# since it only reads.

my $wet_bee = WebService::Beeminder->new(token => $token);
my $dry_bee = WebService::Beeminder->new(token => $token, dryrun => 1);

foreach my $bee ($wet_bee, $dry_bee) {

    # This test assumes we have a 'floss' goal. Dental hygiene is important!

    my $data = $bee->datapoints('floss');

    is(ref $data, 'ARRAY', "Datapoints returns an array of entries");

    # Just make sure all the fields are there
    ok($data->[0]{timestamp},       "timestamp");
    ok(defined $data->[0]{comment}, "comment");
    ok(defined $data->[0]{value},   "value");
    ok($data->[0]{updated_at},      "updated_at");
    ok($data->[0]{id},              "id");
}

# Test adding a datapoint.

my $value   = sprintf('%.4f', rand(10)) +0; # +0 to remove trailing zeroes
my $comment = "Testing WebService::Beeminder v" 
            . $wet_bee->VERSION . " (value: $value)";

my $result = $wet_bee->add_datapoint(
    goal    => $TEST_GOAL,
    value   => $value,
    comment => $comment,
);

is($result->{value},   $value,   "add_datapoint: value");
is($result->{comment}, $comment, "add_datapoint: comment");

# Now let's fetch that datapoint and make sure it's there!

my $data = $wet_bee->datapoints($TEST_GOAL);

is($data->[0]{value},   $value,   "retrieve: value");
is($data->[0]{comment}, $comment, "retrieve: comment");

done_testing;
