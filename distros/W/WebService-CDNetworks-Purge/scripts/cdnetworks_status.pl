#!/usr/bin/env perl

use strict;
use warnings;

use Try::Tiny;
use Data::Dumper;
use Getopt::Long;

use WebService::CDNetworks::Purge;

sub status {

	my ($username, $password, $pid) = @_;

	my $purger = WebService::CDNetworks::Purge -> new({
		'username' => $username,
		'password' => $password,
	});

	try {
		print Dumper($purger -> status($pid));
	} catch {
		die 'Error getting status. Exception: ' . $_;
	};

}

sub main {

	my $username;
	my $password;
	my $pid;

	GetOptions(
		'username=s' => \$username,
		'password=s' => \$password,
		'pid=s'      => \$pid,
	) or die('Error in command line arguments!');

	status($username, $password, $pid);

}

main(@ARGV) unless caller;

