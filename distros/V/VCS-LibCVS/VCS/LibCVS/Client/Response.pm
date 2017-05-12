#
# Copyright (c) 2003,2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::Client::Response;

use strict;
use Carp;

=head1 NAME

VCS::LibCVS::Client::Response - a response in the CVS client protocol

=head1 SYNOPSIS

  my @responses = Client::Response->read_from_server($server_conn);
  if (($responses[-1]->isa("VCS::LibCVS::Client::Response::error"))) {
    my $errors;
    foreach my $resp (@responses) { $errors .= $resp->get_errors(); };
    confess "Request failed: $errors";
  } else {
    # remove the "ok" response
    pop @responses;
  }

=head1 DESCRIPTION

This is a generic superclass for all of the various responses in the cvsclient
protocol.  A response includes zero or more pieces of data (LibCVS::Datum),
which the server sends.  Subclasses of this class should be instantiated, not
this class itself.

If a user of the library cannot handle all types of responses from the server
it can tailor which responses it can receive in the Client; but only before the
connection is established.  To do this, use the valid_responses() routine of
the VCS::LibCVS::Client class.

The data types for each response are predetermined.  Check its documentation to
find out what they are.  Each response can be queried for its type and the data
which it contains, returned as subclasses of LibCVS::Datum.  They

=cut

# There might be good reason to create a new class ResponseList which holds a
# list of responses, because that is how they are typically handled.

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvsroot/libcvs-perl/libcvs-perl/VCS/LibCVS/Client/Response.pm,v 1.27 2005/10/10 12:52:11 dissent Exp $ ';

# Valid_responses is a list of all the responses in this implementation.
# A response registers itself here in its BEGIN block.  It is needed by the
# Valid-Responses Request
use vars ('@Valid_responses');
@Valid_responses = ();

###############################################################################
# Private variables
###############################################################################

# Args         => an array reference of data included in the response
#                 set in the constructor
# ResponseName => the protocol name of this response.
#                 set in the constructor

###############################################################################
# Class routines
###############################################################################

=head1 CLASS ROUTINES

=head2 B<read_from_ioh()>

@responses = Client::Response->read_from_ioh($conn)

Read a list of responses from the server.

=over 4

=item return type: a list of Client::Response

=item argument 1 type: IO::Handle

An IO::Handle from which the list of responses should be read.  Typically this
will be a link directly from the server.

=back

Reads a list of responses from the server, stopping when it receives an "ok" or
"error".  This is the typical way to get a response.  The number of responses
received is unpredictable, as additional responses may be included.

It will block if there is not at least one response.

=cut

# It finds the correct class to create by converting the response name from the
# server into a classname.  This means that the responses have to be named
# predictably.
#
# It could check for constructors in the subtype by calling UNIVERSAL->can()

sub read_from_ioh {
  my $class = shift;
  my $ioh = shift;

  my $cur_response;
  my @responses;

  # Loop until a terminal response is read.
  do {

    # Get the name of the response
    # and gobble the next character, which should be a newline or a space
    my $response_name = "";
    while ((my $char = $ioh->getc()) =~ /\S/) {
      $response_name .= $char;
    }

    # Convert response name into a class name
    my $response_class = $response_name;
    $response_class =~ s/-/_/g;
    $response_class = $class . "::" . $response_class;

    # Create the response of the appropriate type.  If it's unknown there has
    # been a protocol breakdown and we don't know how to proceed, so we just die
    $cur_response = $response_class->new($response_name, $ioh);

    push @responses, $cur_response;

  } while (! $cur_response->terminal());

  return @responses;
}

=head2 B<new()>

$response = Client::Response->new($name, $conn)

Read a single response of the given name from the server.

=over 4

=item return type: a Client::Response

=item argument 1 type: scalar

The name of the response as read from the server.

=item argument 2 type: IO::Handle

A IO::Handle from which the response should be read.  Typically this
will be a link directly from the server.

=back

Reads a single response from the server and creates an object for it.  This
routine should only be called in read_from_server above.  Users of the libary
should call that one, not this one.

The name of the response has already been read from the server.  It is similar
but not identical to the class name of the response.  The only issue is that
the '-' character has been replaced by '_'.

=cut

sub new {
  my ($class, $name, $ioh) = @_;

  my $that = bless {}, $class;
  $that->{ResponseName} = $name;

  my @args = map { "VCS::LibCVS::Datum::$_"->new($ioh); } $that->included_data;
  $that->{Args} = \@args;

  return $that;
}

###############################################################################
# Instance routines
###############################################################################

=head1 INSTANCE ROUTINES

=head2 B<terminal()>

$is_terminal = $response->terminal()

=over 4

=item return type: boolean

Indicates if this is a terminal response.

=back

A terminal response terminates the list of responses that the server is sending
to the user.  Only 'ok' and 'error' are terminal responses.

=cut

sub terminal {
  my $self = shift;
  return 0;
}

=head2 B<included_data()>

@arg_types = $response->included_data()

=over 4

=item return type: list of scalar strings

The types of the args that this response expects

=back

Each string is the name of a subpackage of Datum.  They are used to construct
the response as it is read from the server.

=cut

sub included_data {
  my $self = shift;
  return "String";
}

=head2 B<get_errors()>

$error_message = $response->get_errors()

=over 4

=item return type: scalar string

Returns any error messages

=back

If the response is an error message it will return its string.  Otherwise it
will return undef.

=cut

sub get_errors {
  my $self = shift;
  return;
}

=head2 B<get_message()>

$message = $response->get_message()

=over 4

=item return type: scalar string

Returns any regular messages

=back

If the response is a message (M or MB) it will return its string.  Otherwise it
will return undef.

=cut

sub get_message {
  my $self = shift;
  return;
}

=head2 B<as_protocol_string()>

$response_string = $response->as_protocol_string()

=over 4

=item return type: scalar string

=back

Returns the Client::Response as a string as it was received from the server.

=cut

sub as_protocol_string {
  my $self = shift;
  my $string = $self->{ResponseName} . " ";
  # if there are no args an extra newline is needed after the response name
  if (@{$self->{Args}}) {
    map { $string .= $_->as_protocol_string(); } @{$self->{Args}};
  } else {
    $string .= "\n";
  }
  return $string;
}

=head2 B<data()>

$response_data = $response->data()

=over 4

=item return type: ref to array containing LibCVS::Datum objects

=back

The order of the returned data is documented for each Response.

=cut

sub data() {
  my $self = shift;
  return $self->{Args};
}

###############################################################################
# Private routines
###############################################################################

=head1 SEE ALSO

  VCS::LibCVS::Client
  VCS::LibCVS::Client::Response::Responses
  VCS::LibCVS::Client::Response::FileUpdatingResponses
  VCS::LibCVS::Client::Response::FileUpdateModifyingResponses

=cut

1;
