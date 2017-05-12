=head1 NAME

WebService::UMLSKS::ConnectUMLS - Authenticate the user before accessing UMLSKS with valid username and password.

=head1 SYNOPSIS

=head2 Basic Usage

    use WebService::UMLSKS::ConnectUMLS;

    print "Enter username to connect to UMLSKS:";
	my $username = <>;
	print "Enter password:";
	ReadMode 'noecho';
	my $pwd = ReadLine 0;
	ReadMode 'normal';
	my $c = new Connect;
	my $service = $c->connect_umls( $username, $pwd );


=head1 DESCRIPTION

This module has package ConnectUMLS which has three subroutines 'new', 'get_pt' and 'connect_umls'.
This module takes the username and password from getUserDetails module and connects to the authentication server.
It returns a valid proxy ticket if the user is valid or returns an invalid service object if UMLS sends an invalid proxy ticket.

=head1 SUBROUTINES

The subroutines are as follows:

=cut

###############################################################################
##########  CODE STARTS HERE  #################################################


# This module has package Connect which has three subroutines 'new', 'get_pt' and 'connect_umls'.

use warnings;
use SOAP::Lite;
use strict;
no warnings qw/redefine/; #http://www.perlmonks.org/?node_id=582220
package WebService::UMLSKS::ConnectUMLS;

use Log::Message::Simple qw[msg error debug];

# This sub creates a new object of Connect


=head2 new

This sub creates a new object of ConnectUMLS.

=cut

sub new {
	my $class = shift;
	my $self  = {};
	bless( $self, $class );
	return $self;
}

#-------Following code is taken from the reference program provided by Olivier B.
#-------and is modified according to the need of the application.

# These are the Universal Resource Identifier for WSDL and authentication service.
# These URIs will be used for authentication of the user.
# Please see 'http://umlsks.nlm.nih.gov/DocPortlet/html/dGuide/appls/appls1.html' for details.

my $KSAUTH_WSDL_URI = 
#'http://mor.nlm.nih.gov/auth-ob.wsdl';
'https://uts-ws.nlm.nih.gov/authorization/services/AuthorizationPort?WSDL';
#'http://mor.nlm.nih.gov/auth-ob.wsdl';
my $UMLSKS_WSDL_URI =
'https://uts-ws.nlm.nih.gov/UMLSKS/services/UMLSKSService?wsdl';
#'http://umlsks.nlm.nih.gov/UMLSKS/services/UMLSKSService?WSDL'; 
my $UMLSKS_URI = 
#'https://uts-ws.nlm.nih.gov';
#'https://uts.nlm.nih.gov';
'http://umlsks.nlm.nih.gov';
my $pt_service;
my $pgt;


=head2 connect_umls

This sub takes username and password as arguments 
and returns a proxy ticket object after it authenticates the user.

=cut

sub connect_umls {
	my $self     = shift;
	my $username = shift;
	my $pwd      = shift;
	my $verbose  = shift;

	# Initialize Authentication service.

	$pt_service = SOAP::Lite->service($KSAUTH_WSDL_URI);

	# Get proxy granting ticket.

	$pgt = $pt_service->getProxyGrantTicket( $username, $pwd );

	# If proxy granting ticket is not defined dispalying the error message.

	if ( not defined $pgt ) {
		print "\nYou entered wrong username or password\n";
		return 0;
	}

	# If pgt is obtained, user is a valid user.

	else {
		msg("\nProxy granting ticket : $pgt", $verbose);

		# Get proxy ticket.

		my $pt = get_pt();
		msg("\n Proxy Ticket:$pt",$verbose);

		# Initialize UMLSKS service.

		my $service = SOAP::Lite->service($UMLSKS_WSDL_URI);
		msg("\n service=$service\n",$verbose);
		return $service;

	}

}

# This sub returns the proxy ticket.

=head2 get_pt

This sub returns a proxy ticket.

=cut

sub get_pt {
	return $pt_service->getProxyTicket( $pgt, $UMLSKS_URI );
}

1;

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
