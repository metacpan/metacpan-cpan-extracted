#
# Copyright (c) 2003,2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::Datum::LogMessage;

use strict;
use Carp;

=head1 NAME

VCS::LibCVS::Datum::LogMessage - A cvs log message.

=head1 SYNOPSIS

=head1 DESCRIPTION

A CVS log message for one revision.  It parses a message of this format and
provides access to the various parts:

  revision 1.2.2.1
  date: 2002/11/13 02:29:46;  author: dissent;  state: Exp;  lines: +1 -0
  branches:  1.2.2;
  this is a boring commit with a shortish log message
  but it does have two lines to it

=head1 SUPERCLASS

VCS::LibCVS::Datum

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvsroot/libcvs-perl/libcvs-perl/VCS/LibCVS/Datum/LogMessage.pm,v 1.7 2005/10/10 12:52:12 dissent Exp $ ';

use vars ('@ISA');
@ISA = ("VCS::LibCVS::Datum");

###############################################################################
# Class variables
###############################################################################

###############################################################################
# Private variables
###############################################################################

# $self->{RevisionNumber} object of type VCS::LibCVS::Datum::RevisionNumber
# $self->{Text} scalar string -- the text of the message
# $that->{Date} the date of the commit
# $that->{Author} the author of the commit
# $that->{State} the state of the commit (Exp, . . .)
# $that->{Lines} the + - lines info of the commit
# $that->{Branches} ; separated list of branches from this log
#                   it should be make a list of RevisionNumbers

###############################################################################
# Class routines
###############################################################################

=head1 CLASS ROUTINES

=head2 B<new()>

$log_m = VCS::LibCVS::Datum::LogMessage->new($text)

=over 4

=item return type: VCS::LibCVS::Datum::LogMessage

=item argument 1 type: array ref of lines

Entire log message as a ref to an array of lines, including additional
information in this form:

  revision 1.2
  date: 2002/11/13 02:29:46;  author: dissent;  state: Exp;  lines: +1 -0
  branches:  1.2.2;

It is parsed on creation.

=back

=cut

sub new {
  my $class = shift;
  my $that = bless {}, $class;

  my $log = shift;

  my ($rev_string) = ( (shift @$log) =~ /revision ([0-9.]+)/ );
  $that->{Revision} = VCS::LibCVS::Datum::RevisionNumber->new($rev_string);

  (shift @$log) =~ /date: (.*);  author: (.*);  state: (.*);(  lines: (.*))?/;
  $that->{Date} = $1;
  $that->{Author} = $2;
  $that->{State} = $3;
  $that->{Lines} = $5;

  if ( $$log[0] =~ /^branches:/ ) {
    # Parse out list of branches.  See Issue 24.
    $that->{Branches} = ( (shift @$log) =~ /branches:  (.*)/ );
  }

  $that->{Text} = join("\n", @$log);

  return $that;
}

###############################################################################
# Instance routines
###############################################################################

=head1 INSTANCE ROUTINES

=head2 B<get_revision()>

$revision = $log_m->get_revision()

=over 4

=item return type: VCS::LibCVS::RevisionNumber

=back

=cut

sub get_revision {
  return shift->{Revision};
}

=head2 B<get_text()>

$text = $log_m->get_text()

=over 4

=item return type: scalar string

=back

=cut

sub get_text {
  return shift->{Text};
}

###############################################################################
# Private routines
###############################################################################


=head1 SEE ALSO

  VCS::LibCVS

=cut

1;
