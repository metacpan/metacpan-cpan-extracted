#!/usr/bin/perl
#
# Example script to show how to use Asterisk::Manager
#
# Written by: James Golovich <james@gnuinter.net>
#
#

use lib './lib', '../lib';
use Asterisk::Manager;

$|++;

my $astman = new Asterisk::Manager;

$astman->user('test');
$astman->secret('test');
$astman->host('duff');

$astman->connect || die $astman->error . "\n";

$astman->setcallback('Hangup', \&hangup_callback);
$astman->setcallback('DEFAULT', \&default_callback);


#print STDERR $astman->command('zap show channels');

print STDERR $astman->sendcommand( Action => 'IAXPeers');

#print STDERR $astman->sendcommand( Action => 'Originate',
#					Channel => 'Zap/7',
#					Exten => '500',
#					Context => 'default',
#					Priority => '1' );


$astman->eventloop;

$astman->disconnect;

sub hangup_callback {
	print STDERR "hangup callback\n";
}

sub default_callback {
	my (%stuff) = @_;
	foreach (keys %stuff) {
		print STDERR "$_: ". $stuff{$_} . "\n";
	}
	print STDERR "\n";
}
