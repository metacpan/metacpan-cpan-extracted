use Error::Simple;

=head1 NAME

perfSONAR_PS::Error - A module that provides the exceptions framework for perfSONAR PS

=head1 DESCRIPTION

This module provides the base object for all exception types that will be presented.

=head1 SYNOPSIS

  # first define the errors somewhere
  package Some::Error;
  use base "Error::Simple";
  1;
  

  use Some::Error;

  # you MUST import this, otherwise the try/catch blocks will fail
  use Error qw(:try);  

  # if an error occurs, perfSONAR_PS objects should throw an error eg
  sub openDB {
    my $handle = undef;
    $handle = DBI->connect( ... )
  	  or throw Some::Error( "Could not connect to database: " . $DBI::errstr . "\n" );
  	return $handle;
  }


  ### script.pl ###
  
  # in the calling code
  my $dbh = undef;
  try {
  
    $dbh = &openDB();
  
  }
  catch Some::Error with {
  
    # print the contents of the error object (the string)
    print "An error occurred $@\n";
  
  }
  otherwise {
  
    # some other error occured!
    print "Some unknown error occurred! $@\n";
  
  }
  finally {
  
    print "Done!\n"'
  
  }; 
  
  # don't forget the trailing ';'
  

=cut



package perfSONAR_PS::Error;
use base "Error";

use strict;

our $VERSION = 0.09;

sub new
{
	my $self = shift;
	my $text = "" . shift;
	my @args = ();
	
	local $Error::Depth = $Error::Depth + 1;
	local $Error::Debug = 1;
	
	$self->SUPER::new( -text => $text, @args );
	
}

=head2 toEventType

returns the perfsonar event type for this exception as a string, ensure that 
you throw the appropriate inheritied exception object for automatic eventType
creation.

=cut
sub eventType
{
	my $self = shift;
	my $ex = ref $self;
	# form the '.' notation for the exceptions

	# ensure that camel cased words are separated
	my $s = undef;
	( $s = ref $self ) =~ s/([a-z])([A-Z])/$1_$2/g;

	# remove perfSONAR_PS
	my @str = split /\:\:/, lc $s;
	shift @str;
	
	return join '.', @str;
}

=head2 errorMessage

returns the error message itself (also the same as casting the object as a string)

=cut
sub errorMessage
{
	my $self = shift;
	return $self->text();
}


1;




=head1 SEE ALSO

L<Exporter>, L<Error::Simple>

To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS

Questions and comments can be directed to the author, or the mailing list.

=head1 VERSION

$Id$

=head1 AUTHOR

Yee-Ting Li <ytl@slac.stanford.edu>

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework along
with this software.  If not, see <http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2004-2007, Internet2 and the University of Delaware

All rights reserved.

=cut
 
