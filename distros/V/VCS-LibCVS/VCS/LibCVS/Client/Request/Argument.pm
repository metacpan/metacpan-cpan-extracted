#
# Copyright (c) 2003,2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::Client::Request::Argument;

use strict;
use Carp;

=head1 NAME

VCS::LibCVS::Client::Request::Argument - an Argument request

=head1 SYNOPSIS

  $switch = VCS::LibCVS::Client::Request::Argument->new("-m");
  $msg = VCS::LibCVS::Client::Request::Argument->new("2 line\nmessage");
  $msg = VCS::LibCVS::Client::Request::Argument->new( ["2 line","msg"] );
  $client->submit_request($switch);
  $client->submit_request($msg);

=head1 DESCRIPTION

Used for sending arguments to the server.  These are similar to the cvs
command-line switches.

The only difference from a regular request is the constructor.

An Argument can contain arbitrary characters, including newlines.  In order to
support this the CVS client protocol has a request called Argumentx that
appends a line to a previous Argument request.  This library rolls these two
requests into one object which can handle arguments with multiple lines.

=head1 SUPERCLASS

  VCS::LibCVS::Client::Request

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvsroot/libcvs-perl/libcvs-perl/VCS/LibCVS/Client/Request/Argument.pm,v 1.12 2005/10/10 12:52:11 dissent Exp $ ';

use vars ('@ISA');
@ISA =("VCS::LibCVS::Client::Request");

sub BEGIN { push @VCS::LibCVS::Client::Request::Valid_requests, "Argument"; }

###############################################################################
# Private variables
###############################################################################

###############################################################################
# Class routines
###############################################################################

# Override the constructor, since it must handle a variable number of Datum.  In
# addition we give it the flexibility of allowing newlines in its args_data.
#
# Request::Argument CLASS->new($args_data)
#
# $args_data may be a scalar, or an array ref whose contents are join("\n")ed.

=head1 CLASS ROUTINES

=head2 B<new()>

$request = Client::Request::Argument->new($args_data)

=over 4

=item return type: Client::Request::Argument

=item argument 1 type: . . .

=over 2

=item E<32>E<32>option 1:  scalar

All of the argument data, across any number of lines.

=item E<32>E<32>option 2:  array ref

The elements of the array are joined with newlines between them to form a
scalar which is used as the data.

=back

=back

Constructs and returns a new Argument Request.

=cut

sub new {
  my ($class, $args_data) = @_;

  my $that = bless {}, $class;

  # Request name is always argument.  Change this if you subclass.
  $that->{RequestName} = "Argument";

  # Turn the $args_data into a big long string, split that into an array of
  # lines and store it that way, for easy writing to the server.
  if (!ref($args_data)) {
    $args_data = "" if !defined($args_data);
  } elsif (ref($args_data) eq "ARRAY") {
    $args_data = join "\n", @$args_data;
  } else {
    confess "Wrong type of args_data: " . ref($args_data);
  }

  my @args_data = split /\n/, $args_data;

  # As a hacky way of emulating Argumentx, prepend that string to all but the
  # first Argument.
  for (my $i=1; $i < @args_data; $i++) {
    $args_data[$i] = "Argumentx ".$args_data[$i];
  }
  my @args = map { "VCS::LibCVS::Datum::String"->new($_); } @args_data;

  $that->{Args} = \@args;

  return $that;
}

###############################################################################
# Instance routines
###############################################################################

###############################################################################
# Private routines
###############################################################################

=head1 SEE ALSO

  VCS::LibCVS::Client::Request

=cut

1;
