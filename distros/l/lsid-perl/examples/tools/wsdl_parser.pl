#!/usr/bin/perl
# $Id: wsdl_parser.pl 1512 2005-11-11 21:37:26Z evanchsa-oss $
# =====================================================================
# Copyright (c) 2005 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================

use strict;
use warnings;

use LS::Authority::WSDL;
use LS::Authority::WSDL::Simple;

use Data::Dumper;

use Getopt::Long;
use Pod::Usage;

#
# Argument processing
#
my $debug = 0;

my $help = 0;

my @filenames;


my %getOptions = (

	'help'=>	\$help,
	'<>'=>		\&gatherFilenames,
);


pod2usage("$0: Missing command-line options\nTry $0 --help for more information")
	unless(scalar(@ARGV) > 0);

GetOptions( %getOptions ) || pod2usage(2);

pod2usage(-exitstatus=>0, -verbose=> 2) 
	if($help);


#

while(@filenames) {
	my $wsdl_file = shift(@filenames);
	my $wsdl_data = &read_wsdl($wsdl_file);
	
	print "Parsing WSDL file: $wsdl_file\n\n";
	my $wsdl = LS::Authority::WSDL::Simple->from_xml($wsdl_data);
	unless($wsdl) {
		print STDERR "Unable to parse WSDL file\n";
		exit(-1);
	}
	
	&print_wsdl_details($wsdl);
	
	print "\n\n\n";
}

sub read_wsdl {

	my $filename = shift;
	
	my $data;
	unless(open(WSDL, $filename)) {
		print STDERR "$0: Unable to open WSDL file: $filename\n";
		exit(-1);
	}
	local $/ = undef;
	$data = <WSDL>;
	close(WSDL);
	
	return $data;
}

sub gatherFilenames {
	push @filenames, (shift);	
}

sub print_wsdl_details {
	
	my $wsdl = shift;
	
	print "Target Namespace: ", $wsdl->targetNamespace(), "\n\n";
	
	my $i = 0;
	print "Metadata Locations:\n";
	foreach my $metadata_location (@{ $wsdl->getMetadataLocations() }) {
		print "\tMetadata Location $i:\n";
		&print_wsdl_location_details($metadata_location);
		print "\n";
		
		$i++;
	}
	
	if($i == 0) {
		print "\t\tNo metadata locations found\n";
	}

	print "\n\n";
	
	$i = 0;
	print "Data Locations:\n";
	foreach my $data_location (@{ $wsdl->getDataLocations() }) {
		
		print "\tData Location $i:\n";
		&print_wsdl_location_details($data_location);
		print "\n";
		
		$i++;
	}	

	if($i == 0) {
		print "\t\tNo data locations found\n";
	}
}

sub print_wsdl_location_details {
	
	my $location = shift;

	print "\t\tName: ", $location->name(), "\n";
	print "\t\tParent Service Name: ", $location->parentName(), "\n";
	print "\t\tProtocol: ", $location->protocol(), "\n";
	
	if($location->protocol() eq ${LS::Authority::WSDL::Constants::Protocols::HTTP}) {
		print "\t\tHTTP Method: ", $location->method() ,"\n";
	}
	
	print "\t\tURL: ", $location->url(), "\n";
}




__END__

=head1 NAME

wsdl_parser.pl - Parse WSDL containing LSID services and display its details

=head1 SYNOPSIS

    wsdl_parser.pl [options] [ input file(s) ...]

     Options:
       --debug			Turn on debug information within ODO
       --help           	Usage


=head1 OPTIONS

=over 8

=item B<--debug>

Turn on debug information.

=item B<--help>

Print a help message and exits.

=head1 DESCRIPTION

This program will parse a WSDL document looking for LSID service definitions. 
It will then display the details of the components of the LSID service in a
human readable manner.


Debugging information is available with the <--debug> option.

=cut


__END__
