
=head1 NAME

WebService::UMLSKS::GetCUIs - Get all the preferred terms and CUIs of the input term.

=head1 SYNOPSIS

=head2 Basic Usage


    use WebService::UMLSKS::GetCUIs;
    use WebService::UMLSKS::ConnectUMLS;
    
    my $getCUIs_obj =  new GetCUIs; 
  
    my $CUIs_ref = $getCUIs_obj->get_CUI_info($service,$term,\@sources,$verbose); 
   

=head1 DESCRIPTION

This module has package GetCUIs which has subroutines 'new',get_CUI_info, format _object, format_scalar, format_homogenous_hash, format_homogenous_array and extract_object_class.
This module returns the hash of all preferred terms and CUIs for the input Term.

=head1 SUBROUTINES

The subroutines are as follows:

=cut

###############################################################################
##########  CODE STARTS HERE  #################################################

#use lib "/home/mugdha/UMLS-HSO/UMLS-HSO/WebService-UMLSKS-Similarity/lib";

use strict;
use SOAP::Lite;
use warnings;
use WebService::UMLSKS::ConnectUMLS;
no warnings qw/redefine/;
use WebService::UMLSKS::Similarity;


package WebService::UMLSKS::GetCUIs;


use Log::Message::Simple qw[msg error debug];

my $got_term = 0;
my $term = "";
my $cui = "";
my %TermCUI = ();






# Creating Connect object to call sub get_pt while forming a query.

my $c = WebService::UMLSKS::ConnectUMLS->new;
my $verbose;

=head2 new

This sub creates a new object of GetCUIs.

=cut

sub new {
	my $class = shift;
	my $self  = {};
	bless( $self, $class );
	return $self;
}

=head2 get_CUI_info

This sub queries 'findCUIByExact' by calling run_query sub.

=cut

sub get_CUI_info
{
	my $self = shift;
	my $service = shift;
	my $query_term = shift;
	my $s_ref = shift;
	my $ver = shift;
	
	$verbose = $ver;
	%TermCUI = ();	
	
	my @sources = @$s_ref;
	
	msg("\n In getCUIs sources are : @sources", $verbose);
	# query
	$service->readable(1);
	my $ws_result_ref = run_query($service,
		  
	'findCUIByExact',
		  {
		   casTicket => $c->get_pt(),
		   # use SOAP::Data->type in order to prevent
		   # UTF-8 strings from being encoded into base64
		   # http://cookbook.soaplite.com/#internationalization%20and%20encoding
		   searchString => SOAP::Data->type(string => $query_term),
		   language => 'ENG',
		   release => '2010AB',
		   SABs => [(@sources)],
		   #SABs => [qw( SNOMEDCT )],
		   includeSuppressibles => 'false',
		  },
		 );
		 format_object($ws_result_ref);
		  return(\%TermCUI);

}


=head2 run_query

This sub runs the query to 'findCUIByExact' to get back all the CUIs for term.

=cut

sub run_query {
	my $service = shift;
	my $method_name = shift;
	my @params = @_;

	#warn sprintf "----> %s(%s)\n", $method_name, join(', ', @params);
	my $object_ref = $service->$method_name(@params);
	return $object_ref;
	
	
}
	

# This sub formats the structures returned by the web service. It calls
# the appropriate subroutines depending on the type of structure
# it is called with. If the input reference is a hash reference it calls 
# format_homogenous_hash method. If input is array reference,
# it calls format homogenous array and simillarly for scalar input 
# reference it calls format_scalar.


=head2 format_object

This sub calls appropriate formatting sub.

=cut

sub format_object {
	
	my $object_ref = shift;
	
	#print "in format object";

	unless ( defined $object_ref ) {
		return 'undefined';
	}
	else {
		if ( $object_ref =~ /HASH/o ) {
			return format_homogeneous_hash($object_ref);
		}
		elsif ( $object_ref =~ /ARRAY/o ) {
			return format_homogeneous_array($object_ref);
		}
		elsif ( $object_ref =~ /SCALAR/o ) {
			return format_scalar($object_ref);
		}
		elsif ( defined $object_ref ) {
			return $object_ref;
		}
		else {
			return 'term is not present';
		}
	}
}


=head2 format_scalar

This sub formats scalar object.

=cut


sub format_scalar {
	my $scalar_ref = shift;
	#my $q = shift;
	
	#print "\n In format scalar";
	#print "\n scalar_ref is $$scalar_ref";
	format_object($$scalar_ref);
	
}



=head2 format_homogeneous_hash

This sub formats hash.

=cut

sub format_homogeneous_hash {
	
	my $hash_ref = shift;
	my @incl_rows = ();
	
	foreach my $att (keys %$hash_ref) {		
		if($att =~ /\bCN\b/){
		#print "\n att in hash :$att";
		#print "\n value at att is $hash_ref->{$att}";
		$got_term = 1;
		$term = $hash_ref->{$att};
		
		}	
		if($att =~ /\bCUI\b/){
		#print "\n att in hash :$att";
		#print "\n value at att is $hash_ref->{$att}";
		$cui = $hash_ref->{$att};
		if($got_term == 1){
			$TermCUI{$term} =  $cui;
			$got_term = 0;
		}
		
		}	
		format_object($hash_ref->{$att});		
	}

}



=head2 format_homogeneous_array

This sub formats array.

=cut

sub format_homogeneous_array {
	my $array_ref = shift;
	foreach my $val (@$array_ref) {
	format_object($val);							   
	}	
}




=head2 extract_object_class

This sub is used to remove exact reference to object.

=cut

sub extract_object_class {
	my $object_ref = shift;

	# remove exact reference
	$object_ref =~ s/\(0x[\d\w]+\)$//o;

	my ($class, $type) = split /=/, $object_ref;

	my $res = undef;
	if ($type) {
		$res = $class;
	} else {
		$res = $object_ref;
	}

	return $res;
}

=head2 printHash

This sub prints argument hash.

=cut

sub printHash
{
	my $ref = shift;
	my %hash = %$ref;
	foreach my $key(keys %hash)
	{
		print "\n $key => $hash{$key}";
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

#undef %TermCUI;


#-------------------------------PERLDOC STARTS HERE-------------------------------------------------------------




=head1 SEE ALSO

ValidateTerm.pm  GetUserData.pm  Query.pm  ws-getUMLSInfo.pl 

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
1;
