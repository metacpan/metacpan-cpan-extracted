#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Natural;
local $Time::Keeper::CLOCK = pinned();

# find over a sentence of 200 characters with two mentions in it.
my $n = Time::Keeper::Natural->new(zone => 'Europe/London', locale => 'en-GB');
my $s = 'Thanks for the call earlier. Can we meet again next Tuesday at 3 pm to go over the budget, '
      . 'or failing that on the 20th? Please bring the figures from the review and your notes on the plan with you.';
my @m = $n->find($s);
die 'the sentence is ' . length($s) . ' characters with ' . scalar(@m) . " mentions\n" unless length($s) >= 190 && length($s) <= 210 && @m == 2;
mark_rate('find, 200 characters, two mentions', sub { my @x = $n->find($s) }, 5_000);
done();
