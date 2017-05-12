#!/usr/bin/perl -w
use strict;
use Test::More tests => 8;

# This example is from Wikipedia.
# http://en.wikipedia.org/wiki/Ranked_Pairs

use_ok("Voting::Condorcet::RankedPairs");

my $rp = Voting::Condorcet::RankedPairs->new;
isa_ok($rp,"Voting::Condorcet::RankedPairs");

$rp->add('Memphis'     => 'Nashville',   0.42);
$rp->add('Memphis'     => 'Chattanooga', 0.42);
$rp->add('Memphis'     => 'Knoxville',   0.42);
$rp->add('Nashville'   => 'Chattanooga', 0.68);
$rp->add('Nashville'   => 'Knoxville',   0.68);
$rp->add('Chattanooga' => 'Knoxville',   0.83);

is($rp->winner,'Nashville');

is_deeply(
	[$rp->rankings],[qw(Nashville Chattanooga Knoxville Memphis)],
	"Full rankings listing."
);


is_deeply([ $rp->better_than('Nashville') ],[],"Nobody beats Nashville");
is_deeply([ $rp->better_than('Chattanooga') ],['Nashville'],"Nash beats Chat");

ok(
	eq_set([ $rp->better_than('Knoxville')],[qw(Chattanooga Nashville)]),
	"Chat and Nash beat Knox"
);

ok(
	eq_set([ $rp->better_than('Memphis')], [qw(Nashville Chattanooga Knoxville)]),
	"Everyone beats Memphis"
);
