$VERSION = "0.21";
package Net::NNTP::Functions;
our $VERSION = "0.21";     
# -*- Perl -*- 		# Fri Oct 10 10:17:44 CDT 2003 
#############################################################################
# Written by Tim Skirvin <tskirvin@killfile.org>.  Copyright 2003, Tim
# Skirvin.  Redistribution terms are below.
#############################################################################

=head1 NAME

Net::NNTP::Functions - code to implement NNTP-standard functions

=head1 SYNOPSIS

  use Net::NNTP::Functions;

  my ($first1, $last1) = messagespec( "4-12" );	 # Returns (4, 12)
  my ($first2, $last2) = messagespec( 4 );	 # Returns (4, undef)
  my ($first3, $last3) = messagespec( [4, 12] ); # Returns (4, 12)
  my ($first4, $last4) = messagespec( "4-3" );   # Returns (4, -1)

  my $match = wildmat( 'rec.*', $string );

=head1 DESCRIPTION 

The NNTP specification, as described by Net::NNTP, defines two
speficiations: C<MESSAGE-SPEC>, for defining a range of messages, and
C<PATTERN>, for pattern-matching over NNTP.  These functions attempt to
implement this behaviour.

=cut

###############################################################################
### main() ####################################################################
###############################################################################

use strict;
use Exporter;

use vars qw( @EXPORT @EXPORT_OK @ISA );
@ISA    = "Exporter";
@EXPORT = qw( messagespec wildmat );

###############################################################################
### Methods ###################################################################
###############################################################################

=head2 Functions 

=over 4

=item messagespec ( ARRAYREF | MESSAGEID | MESSAGENUMBER )

Returns an array (or array reference) of two items (FIRST and LAST for
reference), based on the passed item.  If we get an C<ARRAYREF>, it's
assumed to be list of two items FIRST and LAST; if it's a C<MESSAGEID> or
C<MESSAGENUMBER> then FIRST is the value, and LAST is 'undef';

If the LAST item is less than FIRST, then we set LAST to '-1'.  This
allows later functions to (correctly) interpret this for a list of all
items after FIRST.

=cut

sub messagespec {
  my ($spec) = @_;
  my ($first, $last);

  if (ref $spec) {      		  	# List of two numbers
    ($first, $last) = @{$spec};
    $last = -1 if ($last < $first);
  } elsif ($spec =~ m/^\s*(\d+)\s*-?\s*(\d+)\s*$/) { # Two numbers
    $first = $1;  $last = $2;
    $last = -1 if ($last < $first);
  } else {      				# Message-ID or a single number
    $first = $spec;  $last = undef;
  }
  wantarray ? ($first, $last) : [ $first, $last ];
}

=item wildmat ( EXPRESSION, STRING )

Implements the WILDMAT format, as described in the Net::NNTP page (which I
won't repeat here).

Doesn't currently implement the entire functionality; all that currently
works is the anchoring, '*', and '?'.  Ranges of characters ('[]') and
invertings ('^') don't work.  (Correction: they might work, I haven't
tried).

Taken from
http://cvs.trainedmonkey.com/viewcvs.cgi/colobus/colobus?rev=1.41 .

=cut

sub wildmat ($$) {
  my ($expr, $string) = @_;
  $expr =~ s/(?<!\\)\./\\./g;	# Escape '.'
  $expr =~ s/(?<!\\)\$/\\\$/g;	# Escape '$'
  $expr =~ s/(?<!\\)\?/./g;	# '?' functionality
  $expr =~ s/(?<!\\)\*/.*/g;	# '*' functionality
  return $string =~ /^$expr$/;
}

=back

=head1 SEE ALSO

B<Net::NNTP>, specifically its manual page sections on WILDMAT and
MESSAGESPEC.

=head1 TODO

Write the rest of the functionality for wildmat().

=head1 AUTHOR

Tim Skirvin <tskirvin@killfile.org>.  wildmat() in its current form was
written by Jim Winstead Jr.

=head1 COPYRIGHT

Copyright 2003 by Tim Skirvin <tskirvin@killfile.org>.  This code may be
distributed under the same terms as Perl itself.

=cut

1;

###############################################################################
### Version History ###########################################################
###############################################################################
# v0.2a 	Fri Oct 10 10:17:44 CDT 2003 
### First commented version.
# v0.21		Thu Apr 22 11:42:13 CDT 2004 
### No real changes; just version number change.
