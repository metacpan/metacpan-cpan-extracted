#!/usr/bin/perl

use Modern::Perl;

use Test::More tests => 3;

use_ok('WebService::ILS');

my %params = (
    client_id => "DUMMY",
    client_secret => "DUMMY",
);
ok( WebService::ILS->new(%params), "WebService::ILS->new(name => val...)");
ok( WebService::ILS->new(\%params), "WebService::ILS->new({})");
