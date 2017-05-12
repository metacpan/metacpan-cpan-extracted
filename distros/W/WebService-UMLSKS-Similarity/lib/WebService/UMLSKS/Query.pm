
=head1 NAME

WebService::UMLSKS::Query - Query UMLS web services with the query arguments like query term and method name.

=head1 SYNOPSIS

=head2 Basic Usage

  use WebService::UMLSKS::Query;
  use WebService::UMLSKS::ConnectUMLS;

  my $query = new Query;
  my $c = new ConnectUMLS;
  my $method_name = 'findCUIByExact';
  
  $cui = $query->runQuery(
		$service,
		$method_name,
		{
			casTicket => $c->get_pt(),
			searchString => SOAP::Data->type(string => $term),
			language     => 'ENG',
			release      => '2010AA',
			includeSuppressibles => 'false',
		},
	);

  $query -> runQuery($service, $query_term, $method_name, @params);


=head1 DESCRIPTION

This module has package Query which has many subroutines like 'new', 'runQuery' and serialization methods.
This module takes $service object, query term, method name and different parameters of query as arguments.
For valid CUI, it queries UMLS and gets back the hash reference of the information.

=head2 SUBROUTINES

The subroutines are as follows:

=cut


###############################################################################
##########  CODE STARTS HERE  #################################################

use SOAP::Lite;
use warnings;
use strict;
no warnings qw/redefine/;


package WebService::UMLSKS::Query;


use Log::Message::Simple qw[msg error debug];

=head2 new

This sub creates a new object of Query.

=cut

sub new {
	my $class = shift;
	my $self  = {};
	bless( $self, $class );
	return $self;
}


=head2 runQuery

This sub takes $service object, query term, method name and different parameters of query as arguments.
It returns empty if the term does not exist in database or if the web services are not working correctly.
It returns CUI if the query input was a term.
If the query input is CUI, it displays preferred term, definitions with source information and CUI for it.


=cut

sub runQuery {
	my $self        = shift;
	my $service     = shift;
	my $qterm = shift;
	
	my $method_name = shift;
	my @params      = @_;

	# added for debugging
	my $verbose = 0;
	#warn sprintf "----> %s(%s)\n", $method_name, join(', ', @params);

 	use Time::HiRes qw(usleep ualarm gettimeofday tv_interval);
       
	 #open(TIME,">>","time.txt") or die("Error: cannot open file 'time.txt'\n");
	
	my $t0 = [gettimeofday];
	
	# Calling the UMLSKS Web service and receiving the hash reference.
	my $object_ref = $service->$method_name(@params);
	
	my $t0_t1 = tv_interval($t0);        
	  msg("\n $qterm : $t0_t1 secs\n",$verbose);
	  
	 
	  
	# If the returned reference is not defined then display error message.
	
	if ( !defined $object_ref ) {
		print "No information for this CUI.";
		return 'undefined';
	}
	else {

		# If the returned contents array is empty then display error message.

		my $contents_ref = $object_ref->{"contents"};
	#	my @temp = @$contents_ref;
	#	print "\n contents : @temp";
		#if (!defined $contents_ref){
		#	return 'empty';
		#}
		
		if (!defined $contents_ref | !$contents_ref) {

			# if content_ref is empty
			#print "There is no information for your query term/CUI in database.";
			return 'empty';

		}
		

# If UMLSKS returns a defined hash reference then, store and print the information received.

		else {

			if ( $method_name =~ /findCUIByExact/ ) {
			my @cuilist = ();
			#c 1#	$contents_ref = $object_ref->{"contents"};
				foreach my $val (@$contents_ref) {
					while ( my ( $key, $value ) = each(%$val) ) {
						if ( $key =~ /CUI/ ) {					
							my $cui = $value;
							if($cui)
							{
							push(@cuilist,$cui);	
							#	return $cui;
								
							}
							#else
							#{
							#	return 'empty';
							#}
							
						}
					}
				}
				if($#cuilist != -1){
					return \@cuilist;
				}
				else
				{
					return 'empty';
				}
				
			}
			else {
				
					return $object_ref;

			
			}
		}
	}
}

#-------Following code is taken from the reference program provided by Olivier B.
#-------and is modified according to the need of the application.

# UMLSKS returns the information of UMLSKS specific type, so we have create
# a SOAP serializer for each UMLSKS WS mwthods.

# serialization -- UMLSKS-specific types

# NB: create one SOAP::Serializer::as_XXX
#     for each complex type XXX found in the UMLSKS WS methods
#     (see the WSDL file)

=head2 SOAP::Serializer::as_CurrentUMLSRequest

This is SOAP method for serializing UMLS specific types.

=cut

sub SOAP::Serializer::as_CurrentUMLSRequest {
	my ( $self, $value, $name, $type, $attr ) = @_;
	return [ $name, { 'xsi:type' => 'CurrentUMLSRequest', %$attr }, $value ];
}

=head2 SOAP::Serializer::as_ConceptIdExactRequest

This is SOAP method for serializing UMLS specific types.

=cut

sub SOAP::Serializer::as_ConceptIdExactRequest {
	my ( $self, $value, $name, $type, $attr ) = @_;
	return [ $name, { 'xsi:type' => 'ConceptIdExactRequest', %$attr }, $value ];
}

=head2 SOAP::Serializer::as_ConceptIdWordRequest

This is SOAP method for serializing UMLS specific types.

=cut

sub SOAP::Serializer::as_ConceptIdWordRequest {
	my ( $self, $value, $name, $type, $attr ) = @_;
	return [ $name, { 'xsi:type' => 'ConceptIdWordRequest', %$attr }, $value ];
}

=head2 SOAP::Serializer::as_SourceRequest 

This is SOAP method for serializing UMLS specific types.

=cut

sub SOAP::Serializer::as_SourceRequest {
	my ( $self, $value, $name, $type, $attr ) = @_;
	return [ $name, { 'xsi:type' => 'SourceRequest', %$attr }, $value ];
}

=head2 SOAP::Serializer::as_RestrictedSearchStringRequest

This is SOAP method for serializing UMLS specific types.

=cut

sub SOAP::Serializer::as_RestrictedSearchStringRequest {
	my ( $self, $value, $name, $type, $attr ) = @_;
	return [
		$name, { 'xsi:type' => 'RestrictedSearchStringRequest', %$attr }, $value
	];
}

=head2 SOAP::Serializer::as_ConceptRequest

This is SOAP method for serializing UMLS specific types.

=cut

sub SOAP::Serializer::as_ConceptRequest {
	my ( $self, $value, $name, $type, $attr ) = @_;
	return [ $name, { 'xsi:type' => 'ConceptRequest', %$attr }, $value ];
}

=head2 SOAP::Serializer::as_TermGroup

This is SOAP method for serializing UMLS specific types.

=cut

sub SOAP::Serializer::as_TermGroup {
	my ( $self, $value, $name, $type, $attr ) = @_;
	return [ $name, { 'xsi:type' => 'TermGroup', %$attr }, $value ];
}

1;

#-------------------------------PERLDOC STARTS HERE-------------------------------------------------------------


=head1 SEE ALSO

ValidateTerm.pm  GetUserData.pm   ConnectUMLS.pm  ws-getUMLSInfo.pl ws-getAllowablePath.pl

=cut


=head1 AUTHORS

Mugdha Choudhari,             University of Minnesota Duluth
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
