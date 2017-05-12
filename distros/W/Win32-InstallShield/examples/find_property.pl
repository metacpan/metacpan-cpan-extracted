#!/usr/bin/env perl
#
# Win32::InstallShield example
#
# This script will display the value for any properties 
# that match the string you specify on the command line.
#

use Win32::InstallShield;
use warnings;
use strict;

main();

sub main {
	my ($ism_file, $property) = @ARGV;
	unless(defined($property) and defined($ism_file)) {
		print "Usage: $0 <ism_file> <property_name>\n";
		exit;
	}

	my $is = Win32::InstallShield->new();

	# load the ism file the user specified
	$is->loadfile( $ism_file ) or die "Unable to load $ism_file";

	# perform the search, using the supplied string as a 
	# case-insensitive regex. since we're only specifying the
	# property name, the other columns will be ignored when
	# searching.
	my $return = $is->searchHash_Property( 
		{ 
			Property => qr/$property/i 
		} 
	);

	# if there were no matching rows, we will get an empty
	# arrayref back. 
	if(@{$return}) {

		# each entry in the array will be a hash describing
		# a single table row that matched
		foreach my $row (@{$return}) {
			printf "%30s %40s\n", $row->{'Property'}, $row->{'Value'};
		}
	} else {
		print "No properties matched '$property'\n";
	}
}
