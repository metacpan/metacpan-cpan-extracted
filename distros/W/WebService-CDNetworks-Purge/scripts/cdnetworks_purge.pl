#!/usr/bin/env perl

use strict;
use warnings;

use Try::Tiny;
use Data::Dumper;
use Getopt::Long;

use WebService::CDNetworks::Purge;

sub purge {

	my ($username, $password, $domain, $paths) = @_;

	my $purger = WebService::CDNetworks::Purge -> new({
		'username' => $username,
		'password' => $password,
	});

	try {
		print Dumper($purger -> purgeItems($domain, $paths));
	} catch {
		die "Error purging domain: $domain and paths" . join(',', @$paths) . ' and exception: ' . $_;
	};

}

sub main {

	my $username;
	my $password;
	my $domain;
	my @paths;

	GetOptions(
		'username=s' => \$username,
		'password=s' => \$password,
		'domain=s'   => \$domain,
		'path=s'     => \@paths,
	) or die('Error in command line arguments!');

	purge($username, $password, $domain, \@paths);

}

main(@ARGV) unless caller;

