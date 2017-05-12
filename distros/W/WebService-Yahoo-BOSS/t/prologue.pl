#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use WebService::Yahoo::BOSS;

plan skip_all => "YBOSS_CKEY environment not set"
    unless $ENV{YBOSS_CKEY};
plan skip_all => "YBOSS_CSECRET environment not set"
    unless $ENV{YBOSS_CSECRET};

my $boss = WebService::Yahoo::BOSS->new(
    ckey    => $ENV{YBOSS_CKEY},
    csecret => $ENV{YBOSS_CSECRET}
);
isa_ok( $boss, 'WebService::Yahoo::BOSS' );

$boss; # return value
