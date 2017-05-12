
=head1 NAME

WebService::UMLSKS::ValidateTerm - Get the query term/CUI from calling program and validate the term/CUI.

=head1 SYNOPSIS

=head2 Basic Usage

  use WebService::UMLSKS::ValidateTerm;  
  
  print "\nEnter query term/CUI:";
  my $term = <>;  
  my $valid      = new ValidateTerm;
  my $isTerm_CUI = $valid->validateTerm($term);


=head1 DESCRIPTION

This module has package ValidateTerm which has two subroutines 'new' and 'validateTerm'.
This module takes the query term from calling program (getUMLSInfo.pl) and validates it.
It returns values depending on whether the query is term or CUI.


=head1 SUBROUTINES

The subroutines are as follows:

=cut


###############################################################################
##########  CODE STARTS HERE  #################################################

use warnings;
use strict;

no warnings qw/redefine/;


# This is ValidateTerm package which has two subroutines 'new' and 'validateTerm'.
package WebService::UMLSKS::ValidateTerm;

# This sub creates a new object of ValidateTerm

=head2 new

This sub creates a new object of ValidateTerm. 

=cut

sub new {
	my $class = shift;
	my $self  = {};
	bless( $self, $class );
	return $self;
}

# This sub tekes query term as an argument and validates it.
# It returns 2 if term is a valid CUI and returns 3 if term is a query term.
# It also displays error messages if the CUI is invalid.
# A valid CUI is a string thats starts with capital 'C' and is 
# followed by seven digits and all digits are not zero at one time
# i.e., C0000000 is a invalid CUI.

=head2 validateTerm

This sub takes the query term from calling program (getUMLSInfo.pl) and validates it.
It returns '2' if term is valid CUI.
It returns '3' if term is valid term.
In the case of both invalid term or invalid CUI, it returns '10'.

=cut

sub validateTerm {

	my $self = shift;
	my $term = shift;
	if ( $term =~ /^[cC][0-9]/ ) {
		if ( $term =~ /^C\d{7}$/ ) {
			if ( $term =~ /C0000000/ ) {
				#print "It is a invalid CUI.";
				return 'invalid';
			}
			else {

				#print "it is a CUI";
				return 'cui';
			}
		}
		else {
			#print "It is a invalid CUI.";
			return 'invalid';
		}
	}
	else {

		#print "term";
		return 'term';
	}

}

1;

#-------------------------------PERLDOC STARTS HERE-------------------------------------------------------------

 
=head1 SEE ALSO

ConnectUMLS.pm  GetUserData.pm  Query.pm  ws-getUMLSInfo.pl 

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
