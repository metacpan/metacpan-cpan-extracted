# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Connector::RequestBase;

=pod

=head1 NAME

Wombat::Connector::RequestBase - internal request base class

=head1 SYNOPSIS

  package My::Connector::Request;

  use base qw(Wombat::Connector::RequestBase);

=head1 DESCRIPTION

Convenience base implementation of B<Wombat::Request> and
B<Servlet::ServletRequest> which can be used for most connectors. Only
connector-specific methods need to be implemented.

=cut

use base qw(Wombat::Request);
use fields qw(application authorization connector facade handle response);
use fields qw(socket wrapper attributes characterEncoding contentLength);
use fields qw(contentType defaultLocale input locales parameters protocol);
use fields qw(reader remoteAddr remoteHost scheme serverName serverPort);
use fields qw(secure);
use strict;
use warnings;

use Servlet::Util::Exception ();
use Wombat::Connector::RequestFacade ();
use Wombat::Connector::RequestHandle ();
use Wombat::Globals ();
use Wombat::Util::RequestUtil ();

=pod

=head1 CONSTRUCTOR

=over

=item new()

Construct and return a B<Wombat::Connector::RequestBase> instance,
initializing fields appropriately. If subclasses override the
constructor, they must be sure to call

  $self->SUPER::new();

=back

=cut

sub new {
    my $self = shift;
    my $facade = shift;

    $self = fields::new($self) unless ref $self;

    $self->recycle($facade);

    return $self;
}

=pod

=head1 ACCESSOR METHODS

=over

=item getApplication()

Return the Application within which this request is being processed.

=cut

sub getApplication {
    my $self = shift;

    return $self->{application};
}

=pod

=item setApplication($application)

Set the Application within which this request is being processed. This
must be called as soon as the appropriate Application is identified,
because it enables parsing of the request URI.

B<Parameters:>

=over

=item $application

the B<Wombat::Application> within which the request is being processed

=back

=cut

sub setApplication {
    my $self = shift;
    my $application = shift;

    $self->{application} = $application;

    return 1;
}

=pod

=item getAttribute($name)

Return the value of the named attribute.

B<Parameters:>

=over

=item $name

the name of the attribute

=back

=cut

sub getAttribute {
    my $self = shift;
    my $name = shift;

    return $self->{attributes}->{$name};
}

=pod

=item getAttributeNames()

Return an array containing the names of the attributes available to
this request.

=cut

sub getAttributeNames {
    my $self = shift;

    my @attributes = keys %{ $self->{attributes} };

    return wantarray ? @attributes : \@attributes;
}

=pod

=item removeAttribute($name)

Remove the named attribute from this request.

B<Parameters:>

=over

=item $name

the name of the attribute

=back

=cut

sub removeAttribute {
    my $self = shift;
    my $name = shift;

    delete $self->{attributes}->{$name};

    return 1;
}

=pod

=item setAttribute($name, $value)

Set the named attribute in this request.

B<Parameters:>

=over

=item $name

the name of the attribute

=item $value

the value to be set, a scalar or a reference

=back

=cut

sub setAttribute {
    my $self = shift;
    my $name = shift;
    my $value = shift;

    $self->{attributes}->{$name} = $value;

    return 1;
}

=pod

=item getAuthorization()

Return the authorization credentials sent with this request.

=cut

sub getAuthorization {
    my $self = shift;

    return $self->{authorization};
}

=pod

=item setAuthorization($authorization)

Sets the authorization credentials sent with this request.

B<Parameters:>

=over

=item $authorization

the authorization credentials

=back

=cut

sub setAuthorization {
    my $self = shift;
    my $authorization = shift;

    $self->{authorization} = $authorization;

    return 1;
}

=pod

=item getCharacterEncoding()

Return the name of the character encoding used in the body of this
request.

=cut

sub getCharacterEncoding {
    my $self = shift;

    return $self->{characterEncoding};
}

=pod

=item setCharacterEncoding($name)

Set the name of the character encoding used for the body of this
request. This method must be called prior to reading request
parameters or reading input using C<getReader()>.

B<Parameters:>

=over

=item $name

the name of the encoding

=back

B<Throws:>

=over

=item B<Servlet::Util::UnsupportedEncodingException>

if this is not a valid encoding

=back

=cut

sub setCharacterEncoding {
    my $self = shift;
    my $enc = shift;

    $self->{characterEncoding} = $enc;

    return 1;
}

=pod

=item getConnector()

Return the Connector through which this request was received.

=cut

sub getConnector {
    my $self = shift;

    return $self->{connector};
}

=pod

=item setConnector($connector)

Set the Connector through which this request was received.

B<Parameters:>

=over

=item $connector

the B<Wombat::Connector> that received the request

=back

=cut

sub setConnector {
    my $self = shift;
    my $connector = shift;

    $self->{connector} = $connector;

    return 1;
}

=pod

=item getContentLength()

Return the content length, in bytes, of the request body provided by
the input handle.

=cut

sub getContentLength {
    my $self = shift;

    return $self->{contentLength};
}

=pod

=item setContentLength($length)

Set the length, in bytes, of the request body provided by the input
handle.

B<Parameters:>

=over

=item $length

the content length in bytes

=back

=cut

sub setContentLength {
    my $self = shift;
    my $length = shift;

    $self->{contentLength} = $length;

    return 1;
  }

=pod

=item getContentType()

Return the MIME type of the body of the request.

=cut

sub getContentType {
    my $self = shift;

    return $self->{contentType};
}

=pod

=item setContentType($type)

Set the MIME type of the body of this Request. If the C<charset> parameter is
specified, the character encoding of this Request is also set.

B<Parameters:>

=over

=item $type

the MIME type

=back

=cut

sub setContentType {
    my $self = shift;
    my $type = shift;

    $self->{contentType} = $type;
    my $charset = Wombat::Util::RequestUtil->parseCharacterEncoding($type);
    $self->{characterEncoding} = $charset if $charset;

    return 1;
}

=pod

=item getHandle()

Return the underlying input handle associated with this
request. Usually the Socket and Handle for the request are the same
object, but this is not required.

=cut

sub getHandle {
    my $self = shift;

    return $self->{handle};
}

=pod

=item setHandle($handle)

Set the input handle ssociated with this request.

B<Parameters:>

=over

=item $handle

the B<IO::Handle> associated with this request

=back

=cut

sub setHandle {
    my $self = shift;
    my $handle = shift;

    $self->{handle} = $handle;
}

=pod

=item getInputHandle()

Return the B<Servlet::ServletInputHandle> that wraps the underlying
input handle (see C<getHandle()>. The default implementation returns a
handle created by C<createInputHandle()>.

B<Throws:>

=over

=item B<Servlet::Util::IllegalStateException>

if C<getReader()> has already been called for this request

=item B<Servlet::Util::IOException>

if an input or output exception occurred

=back

=cut

sub getInputHandle {
    my $self = shift;

    if ($self->{reader}) {
        my $msg = "getInputHandle: reader already obtained";
        Servlet::Util::IllegalStateException->throw($msg);
    }

    $self->{input} ||= $self->createInputHandle();

    return $self->{input};
}

=pod

=item getLocale()

Return the preferred locale that the client will accept content in,
based on the value for the first I<Accept-Language> header that was
encountered. If the request did not specify a preferred language, the
server's default locale is returned.

=cut

sub getLocale {
    my $self = shift;

    return $self->{locales}->[0] || $self->{defaultLocale};
}

=pod

=item getLocales()

Return the set of preferred locales specified by the client, based on
the values for any I<Accept-Language> headers that were
encountered. If the request did not specify a preferred language, the
server's default locale is returned.

=cut

sub getLocales {
    my $self = shift;

    my @locs = @{ $self->{locales} };
    push @locs, $self->{defaultLocale} unless @locs;

    return wantarray ? @locs : \@locs;
}

=pod

=item addLocale($loc)

Add a locale to the set of preferred Locales for this Request.

B<Parameters:>

=over

=item $loc

the locale to add

=back

=cut

sub addLocale {
    my $self = shift;
    my $loc = shift;

    push @{ $self->{locales} }, $loc;

    return 1;
  }

=pod

=item clearLocales()

Clear the list of locales for this Request.

=cut

sub clearLocales {
    my $self = shift;

    $self->{locales} = [];

    return 1;
}

=pod

=item getParameter($name)

Return the value of the named request parameter. If more than one
value is defined, return only the first one.

B<Parameters:>

=over

=item $name

the name of the parameter

=back

=cut

sub getParameter {
    my $self = shift;
    my $name = shift;

    my $param = $self->{parameters}->{$name};

    return defined $param ? $param->[0] : '';
}

=pod

=item getParameterMap()

Return a hash of the parameters of this Request. The keys of the hash
are the parameter names, and the values of the hash are arrays of
parameter values.

=cut

sub getParameterMap {
    my $self = shift;

    my %params;
    for my $name ($self->getParameterNames()) {
        $params{$name} = $self->getParameterValues($name);
    }

    return wantarray ? %params : \%params;
}

=pod

=item getParameterNames()

Return an array containing the names of the parameters contained in
this Request.

=cut

sub getParameterNames {
    my $self = shift;

    my @names = keys %{ $self->{parameters} };

    return wantarray ? @names : \@names;
}

=pod

=item getParameterValues($name)

Return an array containing all of the values of the named request
parameter.

B<Parameters:>

=over

=item $name

the name of the parameter

=back

=cut

sub getParameterValues {
    my $self = shift;
    my $name = shift;

    my @vals;
    my $param = $self->{parameters}->{$name};
    push @vals, @$param if defined $param;

    return wantarray ? @vals : \@vals;
}

=pod

=item addParameter($name, @values)

Add a named parameter with one or more values to this Request.

B<Parameters:>

=over

=item $name

the name of the parameter to add

=item @values

a list of one or more parameter values, scalar or C<undef>

=back

=cut

sub addParameter {
    my $self = shift;
    my $name = shift;

    $self->{parameters}->{$name} ||= [];

    push @{ $self->{parameters}->{$name} }, @_;

    return 1;
  }

=pod

=item clearParameters()

Clear the set of parameters for this Request.

=cut

sub clearParameters {
    my $self = shift;

    $self->{parameters} = {};

    return 1;
}

=pod

=item getProtocol()

Return the name and version of the protocol used for the request.

=cut

sub getProtocol {
    my $self = shift;

    return $self->{protocol};
}

=pod

=item setProtocol($protocol)

Set the name and version of the protocol used for the request in the
form I<protocol/majorVersion.minorVersion>.

B<Parameters:>

=over

=item $protocol

the name and version of the protocol

=back

=cut

sub setProtocol {
    my $self = shift;
    my $protocol = shift;

    $self->{protocol} = $protocol;

    return 1;
}

=pod

=item getReader()

Return the B<XXX> that wraps the ServletInputHandle for this request
(see C<getInputHandle()>. The default implementation returns a
B<XXX> wrapped around handle created by C<createInputHandle()>.

B<Throws:>

=over

=item B<Servlet::Util::UnsupportedEncodingException>

if the character encoding used is not supported and the text cannot be
decoded

=item B<Servlet::Util::IllegalStateException>

if C<getInputHandle()> has already been called for this request

=item B<Servlet::Util::IOException>

if an input or output exception occurred

=back

=cut

sub getReader {
    my $self = shift;

    return $self->{reader} if $self->{reader};

    if ($self->{input}) {
        my $msg = "getReader: output handle already obtained";
        Servlet::Util::IllegalStateException->throw($msg);
    }

    my $encoding = $self->getCharacterEncoding() || 'ISO-8859-1';

    # XXX: how to know if an encoding is supported?
    unless (uc $encoding eq 'ISO-8859-1') {
        my $msg = "getReader: unsupported character encoding [$encoding]";
        Servlet::Util::UnsupportedEncodingException->throw($msg);
    }

    # XXX: wrap reader class around this handle
    $self->{reader} = $self->createInputHandle();

    return $self->{reader};
}

=pod

=item getRemoteAddr()

Return the remote IP address of the client making this request.

=cut

sub getRemoteAddr {
    my $self = shift;

    return $self->{remoteAddr};
}

=pod

=item setRemoteAddr($addr)

Set the remote IP address of the client making this request. This
value will be used to resolve the name of the remote host if necessary
(see C<getRemoteHost()>).

B<Parameters:>

=over

=item $addr

the remote IP address

=back

=cut

sub setRemoteAddr {
    my $self = shift;
    my $remote = shift;

    $self->{remoteAddr} = $remote;

    return 1;
}

=pod

=item getRemoteHost()

Return the remote host name of the client making this request.

=cut

sub getRemoteHost {
    my $self = shift;

    return $self->{remoteHost};
}

=pod

=item setRemoteHost($host)

Set the remote host name of the client making this request.

B<Parameters:>

=over

=item $host

the remote host name

=back

=cut

sub setRemoteHost {
    my $self = shift;
    my $host = shift;

    $self->{remoteHost} = $host;

    return 1;
}

=pod

=item getRequest()

Return the ServletRequest for which this object is the facade.

=cut

sub getRequest {
    my $self = shift;

    return $self->{facade};
}

=pod

=item getRequestDispatcher($path)

Return a B<Servlet::RequestDispatcher> object that acts as a wrapper
for the resource located at the given path. The path may be absolute
(relative to the context path) or relative to the current request URI.

B<Parameters:>

=over

=item I<$path>

The path to the resource

=back

=cut

sub getRequestDispatcher {
    my $self = shift;
    my $path = shift;

    return undef unless $self->{application};
    return undef unless defined $path;

    if ($path !~ m|^/|) {
        # XXX convert request-relative path to context-relative path
    }

    my $context = $self->{application}->getServletContext();
    return $context->getRequestDispatcher($path);
}

=pod

=item getResponse()

Return the Response with which this request is associated.

=cut

sub getResponse {
    my $self = shift;

    return $self->{response};
}

=pod

=item setResponse()

Set the Response with which this request is associated.

B<Parameters:>

=over

=item $response

the B<Wombat::Response> with which this request is associated

=back

=cut

sub setResponse {
    my $self = shift;
    my $response = shift;

    $self->{response} = $response;
}

=pod

=item getScheme()

Return the name of the scheme used to make this request.

=cut

sub getScheme {
    my $self = shift;

    return $self->{scheme};
}

=pod

=item setScheme($scheme)

Set the name of the scheme used to make this request, for example
I<http>, I<https>, or I<ftp>.

B<Parameters:>

=over

=item $scheme

the name of the scheme

=back

=cut

sub setScheme {
    my $self = shift;
    my $scheme = shift;

    $self->{scheme} = $scheme;

    return 1;
}

=pod

=item isSecure()

Return a flag indicating whether or not this request was made using a
secure channel.

=cut

sub isSecure {
    my $self = shift;

    return $self->{secure};
}

=pod

=item setSecure($flag)

Set a flag indicating whether or not the request was made using a
secure channel.

B<Parameters:>

=over

=item $flag

a boolean value

=back

=cut

sub setSecure {
    my $self = shift;
    my $secure = shift;

    $self->{secure} = $secure;

    return 1;
}

=pod

=item getServerName()

Return the host name of the server which received this request.

=cut

sub getServerName {
    my $self = shift;

    return $self->{serverName};
}

=pod

=item setServerName($name)

Set the host name of the server which received this request.

B<Parameters:>

=over

=item $name

the host name

=back

=cut

sub setServerName {
    my $self = shift;
    my $name = shift;

    $self->{serverName} = $name;

    return 1;
}

=pod

=item getServerPort()

Return the port number on which this request was received.

=cut

sub getServerPort {
    my $self = shift;

    return $self->{serverPort};
}

=pod

=item setServerPort($port)

Set the port number on which this request was received.

B<Parameters:>

=over

=item $port

the port number

=back

=cut

sub setServerPort {
    my $self = shift;
    my $port = shift;

    $self->{serverPort} = $port;

    return 1;
  }

=pod

=item getSocket()

Return the Socket (if any) through which this request was
received. This should B<only> be used to access underlying state
information about the Socket, such as the SSL information of a
B<IO::Socket::SSL>.

=cut

sub getSocket {
    my $self = shift;

    return $self->{socket};
}

=pod

=item setSocket($socket)

Set the Socket (if any) through which this request was received.

B<Parameters:>

=over

=item $socket

the B<IO::Socket> through which this request was received

=back

=cut

sub setSocket {
    my $self = shift;
    my $socket = shift;

    $self->{socket} = $socket;
}

=pod

=item getWrapper()

Return the Wrapper within which this request is being processed.

=cut

sub getWrapper {
    my $self = shift;

    return $self->{wrapper};
}

=pod

=item setWrapper($wrapper)

Set the Wrapper within which this request is being processed. This
must be called as soon as the appropriate Wrapper is identified, and
before the request is ultimately passed to an application servlet.

B<Parameters:>

=over

=item $wrapper

the B<Wombat::Wrapper> associated with this request

=back

=cut

sub setWrapper {
    my $self = shift;
    my $wrapper = shift;

    $self->{wrapper} = $wrapper;
}

=pod

=back

=head1 PUBLIC METHODS

=over

=item createInputHandle()

Create and return a B<Servlet::ServletInputHandle> to read the content
associated with this request.

B<Throws:>

=over

=item Servlet::Util::IOException

if an input or output error occurs

=back

=cut

sub createInputHandle {
    my $self = shift;

    return Wombat::Connector::RequestHandle->new($self);
}

=pod

=item finishRequest()

Perform whatever actions are required to flush and close the input
handle or reader.

B<Throws:>

=over

=item Servlet::Util::IOException

if an input or output error occurs

=back

=cut

sub finishRequest {
    my $self = shift;

#    Wombat::Globals::DEBUG &&
#        $self->debug("finishing request");

    if ($self->{reader}) {
        $self->{reader}->close();
    }

    if ($self->{input}) {
        $self->{input}->close();
    }

    # the underlying handle and socket are the connector's
    # responsibility

    return 1;
}

=pod

=item recycle()

Release all object references and initialize instances variables in
preparation for use or reuse of this object.

=cut

sub recycle {
    my $self = shift;
    my $facade = shift;

    # Wombat::Request instance variables
    $self->{application} = undef;
    $self->{authorization} = undef;
    $self->{connector} = undef;
    $self->{facade} = $facade || Wombat::Connector::RequestFacade->new($self);
    $self->{handle} = undef; # the handle from which request data is read
    $self->{response} = undef;
    $self->{socket} = undef; # the actual request socket, if any
    $self->{wrapper} = undef;

    # Servlet::ServletRequest instance variables
    $self->{attributes} = {};
    $self->{characterEncoding} = undef;
    $self->{contentLength} = undef;
    $self->{contentType} = undef;
    $self->{defaultLocale} = 'en_US'; # XXX
    $self->{input} = undef; # the Servlet::ServletInputHandle wrapper
    $self->{locales} = [];
    $self->{parameters} = {};
    $self->{protocol} = {};
    $self->{reader} = undef; # character handle
    $self->{remoteAddr} = undef;
    $self->{remoteHost} = undef;
    $self->{scheme} = undef;
    $self->{serverName} = undef;
    $self->{serverPort} = undef;
    $self->{secure} = undef;

    return 1;
}

=pod

=back

=cut

# private methods

sub log {
    my $self = shift;

    $self->{connector}->log(@_) if $self->{connector};

    return 1;
}

sub debug {
    my $self = shift;

    # extra check in case we forget to check DEBUG before
    $self->log($_[0], undef, 'DEBUG') if Wombat::Globals::DEBUG;

    return 1;
}

1;
__END__

=pod

=head1 SEE ALSO

L<IO::Handle>,
L<IO::Socket>,
L<Servlet::ServletRequest>,
L<Servlet::ServletServletInputHandle>,
L<Servlet::Util::Exception>,
L<Wombat::Application>,
L<Wombat::Connector>,
L<Wombat::Request>,
L<Wombat::Response>,
L<Wombat::Wrapper>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
