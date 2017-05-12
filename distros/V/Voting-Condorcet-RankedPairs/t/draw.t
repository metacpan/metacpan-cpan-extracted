#!/usr/bin/perl -w
use strict;
use Test::More tests => 1;

use Voting::Condorcet::RankedPairs;

my $rp = Voting::Condorcet::RankedPairs->new;

$rp->add('A' => 'B', 0.5);
$rp->add('C' => 'B', 0.5);
$rp->add('C' => 'A', 0.5);

ok(
	eq_set[$rp->strict_winners],[qw(A B C)],
	"It's a draw."
);
