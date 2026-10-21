#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Natural;
local $Time::Keeper::CLOCK = pinned();
my $n = Time::Keeper::Natural->new(zone => 'Europe/London', locale => 'en-GB');
mark_rate("parse('3 pm BST')", sub { $n->parse('3 pm BST') }, 30_000);
done();
