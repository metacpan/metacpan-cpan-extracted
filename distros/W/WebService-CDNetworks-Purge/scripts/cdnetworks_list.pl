#!/usr/bin/env perl

use strict;
use warnings;

use Try::Tiny;
use Data::Dumper;
use Getopt::Long;

use WebService::CDNetworks::Purge;

sub list {

	my ($username, $password) = @_;

	my $purger = WebService::CDNetworks::Purge -> new({
		'username' => $username,
		'password' => $password,
	});

	try {
		print Dumper($purger -> listPADs());
	} catch {
		die 'Error listing PADs. Exception: ' . $_;
	};

}

sub main {

	my $username;
	my $password;

	GetOptions(
		'username=s' => \$username,
		'password=s' => \$password,
	) or die('Error in command line arguments!');

	list($username, $password);

}

main(@ARGV) unless caller;

