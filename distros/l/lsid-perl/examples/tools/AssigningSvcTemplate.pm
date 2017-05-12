# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================


package YourPackage::AssigningSvcImpl;

use strict;
use warnings;



#
# This is a sample implementation (incomplete) 
# of an LSID Assigning service.
#
#
# It's useful for understanding what information is sent back and forth
# between the client and the service.
#


#
# Input parameters
#
# 1. authority - scalar string 
# 2. namespace - scalar string
# 3. properties list - An arrayref of hashrefs in the form name=>value
#
# Return value format
#
# An LSID (LS::ID object)
#
sub assignLSID {

	my $self = shift;

	my $authority = shift;
	my $namespace = shift;

	my $properties_ref = shift;

	######## EXAMPLE CODE
	#
	# Prints out the parameters
	#
	print STDERR "assignLSID($authority, $namespace, { ";

	foreach my $nv (@{ $properties_ref }) {

		my $n = keys(%{ $nv })->[0];
		my $v = $nv->{$n};

		print STDERR "'$n'=> $v ";
	}
	print STDERR "} )\n";

	#
	#####

	# Return the appropriate LSID
	#return LS::ID->new( .... );
	return undef;
}

#
# Input parameters
#
# 1. properties list - hashref in the form name=>value 
# 2. List of LSIDs - arrayref of LS::ID objects
#
# Return value format
#
# An LSID (LS::ID object)
#
sub assignLSIDFromList {

	my $self = shift;

	my $properties_ref = shift;
	my $lsid_list_ref = shift;

	######## EXAMPLE CODE
	#
	# Prints out the parameters
	#
	print STDERR "assignLSIDFromList( { ";

	foreach(keys(%{ $properties_ref })) {

		print STDERR "'$_'=> " . $properties_ref->{$_} . " ";
	}
	print STDERR "}, ";

	print STDERR " [ ";
	foreach(@{ $lsid_list_ref }) {

		print STDERR "'$_', ";
	}
	print STDERR " ] );\n";

	#
	#####

	# Return the appropriate LSID
	#return LS::ID->new( .... );
	return undef;
}

#
# Input parameters
#
# 1. authority - scalar string 
# 2. namespace - scalar string
# 3. properties list - hashref in the form name=>value
#
# Return value format
#
# A scalar string
#
sub getLSIDPattern {

	my $self = shift;

	my $authority = shift;
	my $namespace = shift;

	my $properties_ref = shift;

	######## EXAMPLE CODE
	#
	# Prints out the parameters
	#
	print STDERR "getLSIDPattern($authority, $namespace, { ";

	foreach(keys(%{ $properties_ref })) {

		print STDERR "'$_'=> " . $properties_ref->{$_} . " ";
	}
	print STDERR "} )\n";

	#
	#####

	# Return the appropriate LSID
	return 'A_String';
}

# Input parameters
#
# 1. properties list - hashref in the form name=>value
# 2. string list - arrayref of strings in the form [ 'string1', 'string2' ]
#
# Return value format
#
# A scalar string
#
sub getLSIDPatternFromList {

	my $self = shift;

	my $properties_ref = shift;
	my $pattern_list = shift;

	######## EXAMPLE CODE
	#
	# Prints out the parameters
	#
	print STDERR "getLSIDPatternFromList( [ ";

	foreach(keys(%{ $properties_ref })) {

		print STDERR " { '$_'=> " . $properties_ref->{$_} . " }, ";
	}
	print STDERR "], [ ";

	foreach(@{ $pattern_list }) {

		print STDERR "'$_', ";
	}
	print STDERR " ] )\n";

	#
	#####

	# Return the appropriate LSID
	return 'A_String';
}

#
# Input parameters
#
# 1. LSID - An LSID object (LS::ID)
#
# Return value format
#
# An LSID (LS::ID object)
#
sub assignLSIDForNewRevision {

	my $self = shift;

	my $lsid = shift;

	######## EXAMPLE CODE
	#
	# Prints out the parameters
	#
	print STDERR "assignLSIDForNewRevision( " . $lsid->as_string . " )\n";

	#
	#####

	# Return the appropriate LSID
	#return LS::ID->new( .... );
	return undef;
}

#
# Input parameters
#
# - NONE -
#
# Return value format
#
# An arrayref of strings in the form [ 'string1', 'string2' ]
#
sub getAllowedPropertyNames {

	my $self = shift;

}
	return [ 'string1', 'string2' ];

#
# Input parameters
#
# - NONE -
#
# Return value format
#
# An arrayref of hashrefs which contain string pairs:
# [
#	{ 'a'=> '1' },
#	{ 'b'=> '2' },
#	{ 'c'=> '3' },
#	{ 'd'=> '4' } 
# ]
#
sub getAuthoritiesAndNamespaces {

	my $self = shift;

	return [
			{ 'a'=> '1' },
			{ 'b'=> '2' },
			{ 'c'=> '3' },
			{ 'd'=> '4' } 
		];
}

1;

__END__

