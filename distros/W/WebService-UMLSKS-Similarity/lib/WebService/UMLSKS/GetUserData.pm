
=head1 NAME

WebService::UMLSKS::GetUserData - Get username and password from the user.

=head1 SYNOPSIS

=head2 Basic Usage

  use WebService::UMLSKS::GetUserData;

  my $getinfo = new GetUserData;
  my $verbose = 1;
  $service = $getinfo -> getUserDetails($verbose);


=head1 DESCRIPTION

This module has package GetUserData which has two subroutines 'new' and 'getUserDetails'.
This module takes the username and password from user and passes them to authenticate module for authentication.
It gets back a valid proxy ticket if the user is valid or an invalid $service object from the authenticate module.
Then it returns the $service object to the calling program (getUMLSInfo.pl).

=head1 SUBROUTINES

The subroutines are as follows:

=cut

###############################################################################
##########  CODE STARTS HERE  #################################################


#use lib "/home/mugdha/UMLS-HSO/UMLS-HSO/WebService-UMLSKS-Similarity/lib";

use WebService::UMLSKS::ConnectUMLS;
#use authenticate_user;
use warnings;
use strict;
no warnings qw/redefine/;

#use lib "/home/mugdha/workspace/getInfo";

package WebService::UMLSKS::GetUserData;

=head2 new

This sub creates a new object of GetUserData.

=cut

sub new {
	my $class = shift;
	my $self  = {};
	bless( $self, $class );
	return $self;
}

use Term::ReadKey;

=head2 getUserDetails

This sub takes username and password from user through command prompt.

=cut

sub getUserDetails {
	my $self    = shift;
	my $verbose = shift;
	my $username = "";
	my $pwd = "";
	
	# Get username and password to authenticate.
	print "Enter username to connect to UMLSKS:";
	$username = <>;
	chomp $username;

	print "Enter password:";
	ReadMode 'noecho';
	$pwd = ReadLine 0;
	ReadMode 'normal';
	chomp $pwd;
	$self->getService($verbose,$username,$pwd);

}

=head2 getService

This sub returns a service object after it authenticates the user with the help 
of authenticate module.

=cut

sub getService
{
	my $self = shift;
	my $verbose = shift;
	my $username = shift;
	my $pwd = shift;
	my $c = WebService::UMLSKS::ConnectUMLS->new;
	my $service = $c->connect_umls( $username, $pwd, $verbose );
	return $service;
	
}

1;

#-------------------------------PERLDOC STARTS HERE-------------------------------------------------------------


=head1 SEE ALSO

ValidateTerm.pm  ConnectUMLS.pm  Query.pm  ws-getUMLSInfo.pl 

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
