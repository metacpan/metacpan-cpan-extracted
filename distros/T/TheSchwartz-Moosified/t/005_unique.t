#!/usr/bin/perl

use strict;
use warnings;
use t::Utils;
use TheSchwartz::Moosified;

plan tests => 12;

foreach $::prefix ("", "someprefix") {

run_test {
    my $dbh = shift;
    my $client = TheSchwartz::Moosified->new( scoreboard => 1 );
    $client->databases([$dbh]);
    $client->prefix($::prefix) if $::prefix;

    my ($job, $handle);

    # insert a job with unique
    $job = TheSchwartz::Moosified::Job->new(
                                 funcname => 'feed',
                                 uniqkey   => "major",
                                 );
    ok($job, "made first feed major job");
    $handle = $client->insert($job);
    isa_ok $handle, 'TheSchwartz::Moosified::JobHandle';

    # insert again (notably to same db) and see it fails
    $job = TheSchwartz::Moosified::Job->new(
                                 funcname => 'feed',
                                 uniqkey  => "major",
                                 );
    ok($job, "made another feed major job");
    $handle = $client->insert($job);
    ok(! $handle, 'no handle');

    # insert same uniqkey, but different func
    $job = TheSchwartz::Moosified::Job->new(
                                 funcname => 'scratch',
                                 uniqkey   => "major",
                                 );
    ok($job, "made scratch major job");
    $handle = $client->insert($job);
    isa_ok $handle, 'TheSchwartz::Moosified::JobHandle';
};

}