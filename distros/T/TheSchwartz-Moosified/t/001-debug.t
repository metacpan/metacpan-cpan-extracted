#!/usr/bin/perl

use Test::More;
use TheSchwartz::Moosified;

BEGIN {

    eval "use Test::Output;";
    plan skip_all => "Test::Output is required for this test" if $@;

    plan tests => 3;
};

my $client = new TheSchwartz::Moosified;
stderr_is(sub { $client->debug('A') }, '', 'no output');
$client->verbose(1);
stderr_is(sub { $client->debug('A') }, "A\n", 'A after verbose 1');
$client->verbose( sub {
    my $msg = shift;
    print STDERR "[MSG] $msg\n";
} );
stderr_is(sub { $client->debug('A') }, "[MSG] A\n", '[MSG] A after verbose sub');
