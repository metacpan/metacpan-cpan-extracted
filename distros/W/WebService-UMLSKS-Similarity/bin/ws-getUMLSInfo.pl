#!/usr/bin/env perl


#---------------------------PERLDOC STARTS HERE------------------------------------------------------------------

=head1 NAME

ws-getUMLSInfo

=cut

#---------------------------------------------------------------------------------------------------------------------


=head1 DESCRIPTION


This program authenticates user by asking for valid username and password to connect to UMLSKS. Once the user is 
authenticated he can enter different terms and CUIs and get back the information about them from the UMLSKS 
Metathesaurus database. The program queries SNOMED-CT database with the term/CUI user enters and displays information
like its source, CUI, definitions, etc. 

=cut


=head1 SYNOPSIS

=head2 Basic Usuage

=pod

perl ws-getUMLSInfo.pl --verbose 1 --sources SNOMEDCT,MSH --rels PAR,CHD --config configfilename --login loginfilename

--verbose: Sets verbose to true if you give value 1
and thus displays debug information in log for the user.

--sources : UMLS sources can be specified by providing list of sources seperated
by comma. These sources will be used to query and retrieve the information.

--rels :  UMLS relations can be specified by providing list of relations seperated
by comma. These relations will be used to query and retrieve the information.

--config : Instead of providing sources and relations on command line, they can be
specified using a configuration file, which can be provided with this option.
It takes complete path and name of the file. The config file is expected in following format:


=over

=item SAB :: include SNOMEDCT,MSH

=item REL :: include PAR
 
=back 


-login : User can specify login credentials through the file, which should of of form:

=over

=item username :: xyz

=item password :: pqr
 
=back

Follwing is a sample output of the program

=over

=item Enter username to connect to UMLSKS:mchoudhari

=item Enter password: 
																
=item Enter query term/CUI:migraine

=item Query term:migraine  
          
=item Prefered Term:Migraine Disorders
                              
=item DEF:neural condition characterized by a severe recurrent vascular headache, usually on one side of the head, often accompanied by nausea, vomiting, and photophobia, sometimes preceded by sensory disturbances; triggers include allergic reactions, excess carbohydrates or iodine in the diet, alcohol, bright lights or loud noises.

=item SAB:CSP            

=item DEF:A class of disabling primary headache disorders, characterized by recurrent unilateral pulsatile headaches. The two major subtypes are common migraine (without aura) and classic migraine (with aura or neurological symptoms). (International Classification of Headache Disorders, 2nd ed. Cephalalgia 2004: suppl 1)

=item SAB:MSH

=item CUI/s associated:C0149931

=item Enter query term/CUI:stop

=back


=head2 Modules/Packages

=pod 

This program uses following packages:

=over
 
=item package ConnectUMLS

->sub ConnectUMLS::get_pt to get the proxy ticket using a web service.

->sub ConnectUMLS::connect_umls to connect to UMLS by sending username 
and password and getting back a proxy ticket.

=item package ValidateTerm

->sub ValidateTerm::validateTerm to accepts input term and validates it 
for a valid term or a valid CUI.

=item package GetUserData

->sub GetUserData::getUserDetails to get username and password from the user.

=item package Query

->sub Query::runQuery which takes method name, service and other parameters as argument and calls the web service. 
It also displays the information received from the web service and other error messages. 

=back

Other subs which provide the serialization of complex types and UMLSKS specific types.

=cut

#---------------------------------------------------------------------------------------------------------------------------

=head2 Structure

=pod

The authentication process is done by 'authenticate' module and includes four steps:

=over

=item 1. sub Initialize Authentication service.

=item 2. Get username and password from user to get proxy granting ticket. 

=item 3. Get proxy ticket using the proxy granting ticket.

=item 4. Initialize UMLSKS web service using SOAP::Lite.

=cut

=back

=pod 

This programs reads input from the authenticated user and decides whether the input is a valid medical term or valid CUI. 
A valid CUI starts with 'C' followed by exactly seven digits and all seven digits cannot be zeros. An invalid term is the
one that does not exist in UMLSKS database.It gives an error message if user enters invalid term or CUI. 
Then it queries the respective web service with source as SNOMED-CT, UMLSKS version as 2009AA, language as English and other parameters. If the input is a medical term, then 
findCUIByExact web service is called which returns a CUI for the entered term. Then getConceptProperties webservice is
called with the returned CUI, which returns the information about the concept. If the user enters a CUI, directly 
getConceptProperties web service is called to get the information. 

=cut

#------------------------------PERLDOC ENDS HERE------------------------------------------------------------------------------


###############################################################################
##########  CODE STARTS HERE  #################################################


use strict;
use warnings;
use SOAP::Lite;
use Term::ReadKey;

#use lib "/home/mugdha/UMLS-HSO/UMLS-HSO/WebService-UMLSKS-Similarity/lib";

use WebService::UMLSKS::GetUserData;
use WebService::UMLSKS::ValidateTerm;
use WebService::UMLSKS::Query;
use WebService::UMLSKS::ConnectUMLS;
use WebService::UMLSKS::DisplayInfo;
use WebService::UMLSKS::Similarity;
use Getopt::Long;
no warnings qw/redefine/;

#Program that connects to UMLSKS and queries the UMLS through the UMLSKS API to return information for an entered term or CUI.

# Author :			 Mugdha
# Reference:         Program provided by Olivier B., NLM.

#use SOAP::Lite +trace => 'debug';

# This is a verbose variable which is set using the command line argument.
# This is set to true if you use --verbose option.
# This is set to false if you use --noverbose option.

my $verbose = "";
my $sources = "";
my $relations = "";
my $similarity;
my $config_file = "";
my $login_file = "";
my $service = "";
my $cui   = "";

#GetOptions( 'verbose!' => \$verbose );

GetOptions( 'verbose=s' => \$verbose , 'sources=s' => \$sources , 'rels=s' =>\$relations, 'config=s' =>\$config_file,
'login=s' => \$login_file );

#print "\n sources : $sources";

if($config_file ne "")
{
	#print "\n got config file";
	 $similarity = WebService::UMLSKS::Similarity->new({"config" => $config_file});
	
}

else
{
if($sources eq "" && $relations eq "")
{
	# use default things
	#print "\n creating default object of similarity";
	 $similarity = WebService::UMLSKS::Similarity->new();
}
else{

if($sources  ne "" && $relations ne "")
{
	# user specified sources through command line
	my @source_list = split ("," , $sources);
	my @relation_list = split ("," , $relations);
	 $similarity = WebService::UMLSKS::Similarity->new({"sources" =>  \@source_list,
												    	 "rels"   =>  \@relation_list }	);
	
	#$ConfigurationParameters{"SAB"} = \@sources_list;
}
elsif($relations ne "" )
{
	# user specified rels through command line
	my @relation_list = split ("," , $relations);
	 $similarity = WebService::UMLSKS::Similarity->new({ "rels"   =>  \@relation_list });
	
	#$ConfigurationParameters{"REL"} = \@relation_list;
}
elsif($sources ne "")
{
	#print"\n got a source list";
	my @source_list = split ("," , $sources);
	#print "\n sources : @source_list";
	 $similarity = WebService::UMLSKS::Similarity->new({"sources" =>  \@source_list}	);
	
}

}

}
my @sources = @{$similarity->{'SAB'}};
my @relations = @{$similarity->{'REL'}};



# This is used to continue asking for the new term to user unless you enter 'stop'.

my $continue = 1;
my $object_ref;

# Creating object of class GetUserData and call the sub getUserDetails.
# Receive a $service object if the user is a valid user.

my $g       = WebService::UMLSKS::GetUserData->new;
#my $service = $g->getUserDetails($verbose);

if(defined $login_file && $login_file ne "")
{
	# Login details specified through the file
	# call sub getService using object of GetUserData
	# Receive a $service object if the user is a valid user.
	
	my $username = "";
	my $pwd = "";
	
	open( LOGIN, $login_file )
		  or die("Error: cannot open configuration file '$login_file'\n");

		my @login_details = <LOGIN>;
		foreach my $detail (@login_details){
			
			#msg( "\n $detail", $verbose);
			$detail =~ /\s*(.*)\s*::\s*(.*?)$/;
			#print "\n $1 \t $2";
			my $detail_name = $1;
			my $detail_value = $2;
			chomp($detail_value);
			chomp($detail_name);
			if($detail_name ne "" && $detail_value ne ""){
				if($detail_name =~ /\b[Uu]sername\b/){
				$username = $detail_value;
				}
				if($detail_name =~ /\b[pP]assword\b|\b[Pp]wd\b/){
				$pwd = $detail_value;
				}
			}
			else
			{
				print "\n Invalid login file";
				exit;
			}
			
		}
	 $service = $g->getService($verbose, $username, $pwd);
}

else
{
# call the sub getUserDetails.
# Receive a $service object if the user is a valid user.

 $service = $g->getUserDetails($verbose);
	
}



# User enetered wrong username or password.

if ( $service == 0 ) {
	$continue = 0;
}

# Creating Connect object to call sub get_pt while forming a query.

my $c = WebService::UMLSKS::ConnectUMLS->new;


#print $service;

while ( $continue == 1 ) {

	# After the authentication, accept a query term or CUI from the user.

	print "\nEnter query term/CUI:";
	my $term = <>;

	# Remove white spaces.

	chomp($term);

	# If user enters 'stop', exit the program.
	if ( $term =~ /stop/i ) {
		exit;
	}

	# Else continue with asking the new query term.

	else {

		my $qterm = $term;

		#print "term is $term";

# Validate the term by passing it to the sub validateTerm which belongs to class getTerm.
# Create object of class getTerm to access the sub validateTerm.

		my $valid      = WebService::UMLSKS::ValidateTerm->new;
		my $isTerm_CUI = $valid->validateTerm($term);

		#print $isTerm_CUI;
		
		
		if($isTerm_CUI eq 'invalid')
		{
			print "\n Your input is not valid CUI.";
			next;
		}

   # Depending on the value returned by validateTerm form a query for UMLSKS.
   # Creating object of query and passing the method name along with parameters.

		my $query = WebService::UMLSKS::Query->new;
		my @cui_list = ();
		
		
		

# If the input entered by user is term, call findCUIByExact webservice, to get back the CUI.

		if ( $isTerm_CUI eq 'term' ) {
		my $cuilist;
# following sub describes the details like the method name to be called, term to be searched etc.
			$service->readable(1);
			$cuilist = $query->runQuery(
				$service, $qterm,
				'findCUIByExact',
				{
					casTicket => $c->get_pt(),

		   # use SOAP::Data->type in order to prevent
		   # UTF-8 strings from being encoded into base64
		   # http://cookbook.soaplite.com/#internationalization%20and%20encoding
					searchString => SOAP::Data->type( string => $qterm ),
					language     => 'ENG',
					release      => '2009AA',
					#SABs => [( $source )],
					#SABs => [($sources[0])],
					SABs => [(@sources)],
					#SABs => [qw(SNOMEDCT)],
					includeSuppressibles => 'false',
				},
			);
			
			

# runQuery returns undefined value if the entered term does not exist in the UMLS database.
		
			if ($cuilist eq "empty") {
				print "Term/CUI does not exist in currently configured sources.";
				next;
			}

# If the term exists in UMLS, set the returned CUI to current query term, and query again
# with the CUI to get the information about the CUI.

			else {
				if ( $cui =~ /empty|undefined/ ) { # change made , added undefined to return values of run query
					print "\nThere is no information for your input in UMLS using current configuaration.";
					next;
				}
				else {

					@cui_list  = @$cuilist;
					$term = $cui_list[0];

					#print "now term is $cui";
					$isTerm_CUI = 'cui';
				}
			}

		}

		

# If the input entered by the user is a CUI, call getConceptProperties web service and get back the information.

		if ( $isTerm_CUI eq 'cui' ) {

			#print"calling getconceptproperties";

			$service->readable(1);
			$object_ref = $query->runQuery(
				$service, $qterm,
				'getConceptProperties',
				{
					casTicket => $c->get_pt(),

		   # use SOAP::Data->type in order to prevent
		   # UTF-8 strings from being encoded into base64
		   # http://cookbook.soaplite.com/#internationalization%20and%20encoding
					CUI => SOAP::Data->type( string => $term ),

					# CUI => "asfa",
					language => 'ENG',
					release  => '2009AA',
					SABs => [(@sources)],
					#SABs => [qw( SNOMEDCT )],
					includeConceptAttrs  => 'false',
					includeSemanticTypes => 'false',
					includeTerminology   => 'false',
					includeDefinitions   => 'true',
					includeSuppressibles => 'false',

				   # includeRelations     => 'true',
				   # relationTypes        =>  [ 'PAR' ],
				},
			);

			
			unless($object_ref =~ /empty/){
				print "\n  Query term:$qterm";
				my $display_obj =  WebService::UMLSKS::DisplayInfo->new;
				my $object_f = $display_obj->display_object($object_ref);
				unless(!@cui_list){
					print "\n    CUI/s associated : @cui_list";
				}
				print "\n";
			}
			
			else
			{
				print "\nThere is no information for your input in UMLS using current configuaration.";
			}
				
		}
		

	}
}

# Serialization subroutines

# serialization -- non-Perl types / complex types

=head1 SUBROUTINES

=head2 SOAP::Serializer::as_boolean

subroutine for serialization -- non-Perl types / complex types

=cut

sub SOAP::Serializer::as_boolean {
	my ( $self, $value, $name, $type, $attr ) = @_;
	return [ $name, { 'xsi:type' => 'xsd:boolean', %$attr }, $value ];
}

=head2 SOAP::Serializer::as_ArrayOf_xsd_string

subroutine for serialization -- non-Perl types / complex types

=cut

sub SOAP::Serializer::as_ArrayOf_xsd_string {
	my ( $self, $value, $name, $type, $attr ) = @_;
	return [ $name, { 'xsi:type' => 'array', %$attr }, $value ];
}

#-------------------------------PERLDOC STARTS HERE-------------------------------------------------------------


=head1 SEE ALSO

ValidateTerm.pm  GetUserData.pm  Query.pm  ConnectUMLS.pm

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
