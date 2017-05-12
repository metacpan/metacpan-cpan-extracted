#!perl

use strict;
use warnings;
use utf8;

use LWP::Online ':skip_all';
use Test::More 0.88 tests => 3;
use WebService::BambooHR;
my $domain  = 'testperl';
my $api_key = 'bfb359256c9d9e26b37309420f478f03ec74599b';
my $bamboo;
my @changes;

SKIP: {

    my $bamboo = WebService::BambooHR->new(
                        company => $domain,
                        api_key => $api_key);
    ok(defined($bamboo), "create BambooHR class");

    eval {
        @changes = grep { $_->lastChanged lt '2016-02-02T00:00:01Z' }
                   $bamboo->changed_employees('2016-01-01T00:00:01Z');
    };
    ok(!$@ && @changes > 0, 'get changes list');
    my $expected_format = 1;

    foreach my $change (@changes) {
        if (   $change->id !~ /^[0-9]+$/
            || $change->action !~ /^(Inserted|Updated|Deleted)$/
            || $change->lastChanged !~ /^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\+00:00$/)
        {
            $expected_format = 0;
        }
    }

    ok($expected_format, "all changes had expected format");

};

