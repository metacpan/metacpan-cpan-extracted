#!/usr/bin/perl -w
use 5.010;
use strict;
use warnings;
use Test::More;
use WebService::Beeminder;

my $TEST_GOAL = 'wsbm-test';

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

my $bee = WebService::Beeminder->new(token => $token);

# This test assumes we have a 'floss' goal. Dental hygiene is important!

my $data = $bee->goal('floss');

# Make sure at least our title looks reasonable.
is($data->{title},"Floss every tooth for great justice!");
is($data->{datapoints}[0]{id}//"","","No datapoints for basic call");

# Get a goal with datapoints.
my $moar_data = $bee->goal('floss', datapoints=>1);
isnt($moar_data->{datapoints}[0]{id}//"","","Datapoints returned");

done_testing;
