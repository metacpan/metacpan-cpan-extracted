#!/usr/bin/env perl


#---------------------------PERLDOC STARTS HERE------------------------------------------------------------------

=head1 NAME

ws-sample

=cut

#---------------------------------------------------------------------------------------------------------------------


=head1 DESCRIPTION

This a sample program which shows the flow of the complete package and how different modules interact with each other.
This program authenticates user by asking for valid username and password to connect to UMLSKS. Once the user is 
authenticated program takes a term from the user and finds CUI using the UMLSKS Metathesaurus database.
The program queries SNOMED-CT database.

=cut

=head1 SYNOPSIS

=head2 Basic Usuage

=pod

perl ws-sample.pl

Follwing is a sample output

=over

=item Enter username to connect to UMLSKS:mchoudhari

=item Enter password: 

=item Enter query term : hair

=item CUI/s for term hair is : C0018494

=back


=cut

#---------------------------------------------------------------------------------------------------------------------------

#------------------------------PERLDOC ENDS HERE------------------------------------------------------------------------------





#Program that connects to UMLSKS and queries the UMLS through the UMLSKS API to return information for an entered term or CUI.

# Author :			 Mugdha
# Reference:         Program provided by Olivier B., NLM.


use strict;
use warnings;
use SOAP::Lite;

#use lib "/home/mugdha/UMLS-HSO/UMLS-HSO/WebService-UMLSKS-Similarity/lib";

use WebService::UMLSKS::GetUserData;
use WebService::UMLSKS::ValidateTerm;
use WebService::UMLSKS::Query;
no warnings qw/redefine/;


my $verbose = 1;

# Creating object of class GetUserData and call the sub getUserDetails.
# Receive a $service object if the user is a valid user.

my $g       = WebService::UMLSKS::GetUserData->new;
my $service = $g->getUserDetails($verbose);

if($service == 0){
	exit;
}

# Creating Connect object to call sub get_pt while forming a query.

my $c = WebService::UMLSKS::ConnectUMLS->new;

print "\nEnter query term:";

	my $term = <>;

	# Remove white spaces.

	chomp($term);
	
	
# Validate the term by passing it to the sub validateTerm which belongs to class getTerm.
# Create object of class getTerm to access the sub validateTerm.

		my $valid      = WebService::UMLSKS::ValidateTerm->new;
		my $isTerm_CUI = $valid->validateTerm($term);


 # Creating object of query and passing the method name along with parameters.

		my $query = WebService::UMLSKS::Query->new;
		
		my $cuilist;

# Following sub describes the details like the method name to be called, term to be searched etc.
# Using default source SNOMECT to get the CUI back.

			$service->readable(1);
			$cuilist = $query->runQuery(
				$service, $term,
				'findCUIByExact',
				{
					casTicket => $c->get_pt(),

		   # use SOAP::Data->type in order to prevent
		   # UTF-8 strings from being encoded into base64
		   # http://cookbook.soaplite.com/#internationalization%20and%20encoding
					searchString => SOAP::Data->type( string => $term ),
					language     => 'ENG',
					release      => '2010AA',
					SABs => [qw(SNOMEDCT)],
					includeSuppressibles => 'false',
				},
			);

print "\nCUI/s for term $term : @$cuilist\n";

# Serialization subroutines

# serialization -- non-Perl types / complex types

sub SOAP::Serializer::as_boolean {
	my ( $self, $value, $name, $type, $attr ) = @_;
	return [ $name, { 'xsi:type' => 'xsd:boolean', %$attr }, $value ];
}

sub SOAP::Serializer::as_ArrayOf_xsd_string {
	my ( $self, $value, $name, $type, $attr ) = @_;
	return [ $name, { 'xsi:type' => 'array', %$attr }, $value ];
}



#-------------------------------PERLDOC STARTS HERE-------------------------------------------------------------


=head1 SEE ALSO 

getAllowablePath.pl  GetUserData.pm  Query.pm  ConnectUMLS.pm getUMLSInfo.pl 

=cut


=head1 AUTHORS

Mugdha Choudhari             University of Minnesota Duluth
                             E<lt>chou0130 at d.umn.eduE<gt>

Ted Pedersen,                University of Minnesota Duluth
                             E<lt>tpederse at d.umn.eduE<gt>




=head1 COPYRIGHT

Copyright (C) 2011, Mugdha Choudhari, Ted Pedersen

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to 
The Free Software Foundation, Inc., 
59 Temple Place - Suite 330, 
Boston, MA  02111-1307, USA.

=cut

#---------------------------------PERLDOC ENDS HERE---------------------------------------------------------------