#
# Copyright (c) 2003,2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::Client::Request;

use strict;
use Carp;

=head1 NAME

VCS::LibCVS::Client::Request - a request in the CVS client protocol

=head1 SYNOPSIS

  my $mode = VCS::LibCVS::Datum::Mode->new("u=rw,g=rw,o=r");
  my $mod_request = VCS::LibCVS::Client::Request::Modified->
                              new( [ "afile" , $mode, "/tmp/afile" ] );
  $client->submit_request($mod_request);

=head1 DESCRIPTION

This is a generic superclass for all of the various requests in the cvsclient
protocol.  A request includes zero or more pieces of data (LibCVS::Datum),
which are specified when the request is constructed.  A request is submitted to
the server through a Client, which may return some responses.  You should
instantiate subclasses of this class, not this class itself.

The protocol defines which requests will elicit responses, so you can ask a
request if it expects a response.  A given server may not support all requests,
the Client can queried to find out which ones are supported.  Requests other
than those must not be submitted to the server.

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvsroot/libcvs-perl/libcvs-perl/VCS/LibCVS/Client/Request.pm,v 1.23 2005/10/10 12:52:11 dissent Exp $ ';

# Valid_requests is a list of all the requests in this implementation.
# A request registers itself here in its BEGIN block.  It is needed to populate
# the list of valid requests
use vars ('@Valid_requests');
@Valid_requests = ();

###############################################################################
# Private variables
###############################################################################

# It's a hash and keeps these variables:

# RequestName => The name of this request which should be sent to the server
#                Set in constructor
# Args        => A reference to an array of objects of type LibCVS::Datum
#                Set in constructor

###############################################################################
# Class routines
###############################################################################

=head1 CLASS ROUTINES

=head2 B<new()>

$request = Client::Request::SubClass->new($args_data)

Only call this on subclasses of Client::Request.  Some subclasses override this
constructor.

=over 4

=item return type: Client::Request::SubClass

=item argument 1 type: (optional) array ref

A ref to an array which contains the data for constructing the required
Datum's of the Client::Request.  If the Client::Request has no required
Datum's, you may omit the argument (pass undef).

To determine the required data check the Request's documentation, or call the
Request's required_data() routine.

=back

Constructs and returns a new request.

=cut

# A request maintains an internal variable which is its name as it must send to
# the CVS server.  This name can be derived from the name of the class, by
# substituing _'s with -'s.  Rather than write constructors for each subtype, I
# do that substitution here, and set the variable.  It's a little nasty, but it
# works.

sub new {
  my ($class, $args_data) = @_;

  # This class shouldn't be instantiated itself
  die "VCS::LibCVS::Client::Request is an abstract class" if
    $class eq "VCS::LibCVS::Client::Request";

  # Transform the final chunk of the classname into the protocol request name
  my $request_name = $class;
  $request_name =~ s/.*::(.*)/$1/;
  $request_name =~ s/_/-/g;

  my $that = bless {}, $class;
  $that->{RequestName} = $request_name;

  # Process the provided args.
  # For each passed parameter, call the constructor for the expected type of
  # arg.
  $args_data = [] if !defined($args_data);
  my @required_data = $that->required_data;
  confess "Wrong number of args" if (@required_data != @$args_data);
  my @args = map {
    "VCS::LibCVS::Datum::$_"->new(shift(@$args_data));
  } @required_data;
  $that->{Args} = \@args;

  return $that;
}

=head2 B<required_data()>

@request_required_data = $request->required_data()

=over 4

=item return type: list of names of subclasses of Datum

A list of strings which are subpackages of Datum, like ("String",
"DirectoryName", "TagSpec").

=back

The list of data which are required in this request.  Each of the named classes
are subpackages of "VCS::LibCVS::Datum".  This list is used in the construction
of the request, whose parameters must match the names in this list.

=cut

# The default is one simple Datum.  Most subclasses will override this.
sub required_data {
  my $self = shift;
  return "String";
}

###############################################################################
# Instance routines
###############################################################################

=head1 INSTANCE ROUTINES

=head2 B<protocol_print()>

$request->protocol_print($file_handle)

=over 4

=item return type: undef

=item argument 1 type: IO::Handle

=back

Prints the Request to the IO::Handle.  The output will be formatted for sending
to the cvs server, including the placement of newlines.

=cut

# it doesn't use the as_string routine, because we will need to add streaming

sub protocol_print {
  my ($self, $ioh) = @_;
  my $args = $self->{Args};

  $ioh->print($self->{RequestName} . " ") || confess "print 1 to ioh failed";

  # Each Datum ends it submit with a newline.  So if there are none, add one
  ($ioh->print("\n") || confess "print 2 to ioh failed") if (!@$args);

  map { $_->protocol_print($ioh) || confess "print 3 to ioh failed"; } @$args;
}

=head2 B<as_protocol_string()>

$request_string = $request->as_protocol_string()

=over 4

=item return type: string scalar

=back

Returns the Client::Request as a string suitable for being sent to the server,
including the placement of newlines.

=cut

sub as_protocol_string {
  my ($self) = @_;
  my $args = $self->{Args};

  my $string = $self->{RequestName} . " ";

  # Each Datum ends its submit with a newline.  So if there are none, add one
  $string .= "\n" if (!@$args);

  map { $string .= $_->as_protocol_string; } @$args;
  return $string;
}

=head2 B<response_expected()>

$response_expected = $request->response_expected()

=over 4

=item return type: boolean scalar

=back

Indicates if the request expects to elicit a response when submitted to the
server.

=cut

# generally this is based on the capitalization of the first letter of the name
sub response_expected {
  my $self = shift;
  return ($self->{RequestName} =~ /^[a-z]/);
}

=head2 B<name()>

$name = $request->name()

=over 4

=item return type: string scalar

=back

Returns the protocol name of the request.

=cut

sub name {
  my $self = shift;
  return $self->{RequestName};
}

###############################################################################
# Private routines
###############################################################################

=head1 SEE ALSO

  VCS::LibCVS::Datum
  VCS::LibCVS::Client
  VCS::LibCVS::Client::Request::Requests
  VCS::LibCVS::Client::Request::Argument
  VCS::LibCVS::Client::Request::ArgumentUsingRequests

=cut

1;
