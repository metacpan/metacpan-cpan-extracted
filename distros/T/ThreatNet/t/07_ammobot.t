#!/usr/bin/perl

# Test creation of a ThreatNet::Bot::AmmoBot object

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}





# Does everything load?
use Test::More 'tests' => 6;
use ThreatNet::Bot::AmmoBot;
use POE;





#####################################################################
# Object Creation

my $bot = ThreatNet::Bot::AmmoBot->new(
	Nick    => 'Foo',
	Server  => 'irc.freenode.org',
	Channel => '#threatnettest',
	);
isa_ok( $bot, 'ThreatNet::Bot::AmmoBot' );

# Test the accessors
is( ref($bot->args),  'HASH', '->tails returns a hash' );
is( ref($bot->tails), 'HASH', '->tails returns a hash' );
ok( ! $bot->running, '->running returns false' );
is( scalar($bot->files), 0, '->files returns 0' );

ok( $bot->add_file($0), 'Added file' );

${$poe_kernel->[POE::Kernel::KR_RUN]} |= POE::Kernel::KR_RUN_CALLED;
