# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Connector::HttpResponseBase;

=pod

=head1 NAME

Wombat::Connector::HttpResponseBase - internal http response base class

=head1 SYNOPSIS

  package My::Connector::HttpResponse;

  use base qw(Wombat::Connector::HttpResponseBase);

=head1 DESCRIPTION

Convenience base implementation of B<Wombat::HttpResponse> and
B<Servlet::Http::HttpServletResponse> which can be used for most
connectors that implement the HTTP protocol. Only connector-specific
methods need to be implemented. Extends
B<Wombat::Connector::ResponseBase>.

=cut

use base qw(Wombat::HttpResponse Wombat::Connector::ResponseBase);
use fields qw(cookies headers message status);
use strict;
use warnings;

use HTTP::Headers ();
use Servlet::Http::HttpServletResponse ();
use Servlet::Util::Exception ();
use URI ();
use Wombat::Connector::HttpResponseFacade ();
use Wombat::Globals ();
use Wombat::Util::CookieTools ();

use constant STATUS_MESSAGES =>
    {
     100 => 'Continue',
     101 => 'Switching Protocols',
     200 => 'OK',
     201 => 'Created',
     202 => 'Accepted',
     203 => 'Non-Authoritative Information',
     204 => 'No Content',
     205 => 'Reset Content',
     206 => 'Partial Content',
     300 => 'Multiple Choices',
     301 => 'Moved Permanently',
     302 => 'Moved Temporarily',
     303 => 'See Other',
     304 => 'Not Modified',
     305 => 'Use Proxy',
     400 => 'Bad Request',
     401 => 'Unauthorized',
     402 => 'Payment Required',
     403 => 'Forbidden',
     404 => 'Not Found',
     405 => 'Method Not Allowed',
     406 => 'Not Acceptable',
     407 => 'Proxy Authentication Required',
     408 => 'Request Timeout',
     409 => 'Conflict',
     410 => 'Gone',
     411 => 'Length Required',
     412 => 'Precondition Failed',
     413 => 'Request Entity Too Large',
     414 => 'Request URI Too Long',
     415 => 'Unsupported Media Type',
     416 => 'Requested Range Not Satisfiable',
     417 => 'Expectation Failed',
     500 => 'Internal Server Error',
     501 => 'Not Implemented',
     502 => 'Bad Gateway',
     503 => 'Service Unavailable',
     504 => 'Gateway Timeout',
     505 => 'HTTP Version Not Supported',
    };

=pod

=head1 CONSTRUCTOR

=over

=item new()

Construct and return a B<Wombat::Connector::HttpResponseBase>
instance, initializing fields appropriately. If subclasses override the
constructor, they must be sure to call

  $self->SUPER::new();

=back

=cut

sub new {
    my $self = shift;
    my $facade = shift;

    $self = fields::new($self) unless ref $self;
    $self->SUPER::new($facade);

    return $self;
}

=pod

=head1 ACCESSOR METHODS

=over

=item getCookies()

Return the list of Cookies for this Response.

=cut

sub getCookies {
    my $self = shift;

    my @cookies = @{ $self->{cookies} };

    return wantarray ? @cookies : \@cookies;
}

=item addCookie($cookie)

Add the specified Cookie to those that will be included with this Response.

B<Parameters:>

=over

=item $cookie

the B<Servlet::Http::Cookie> to be added

=back

=cut

sub addCookie {
    my $self = shift;
    my $cookie = shift;

    return 1 if $self->isCommitted();
    return 1 if $self->isIncluded();

    push @{ $self->{cookies} }, $cookie;

    return 1;
}

=pod

=item clearCookies()

Clear the list of Cookies for this Response;

=cut

sub clearCookies {
    my $self = shift;

    $self->{cookies} = [];

    return 1;
}

=pod

=item addDateHeader($name, $date)

Add a date value for the named response header.

B<Parameters:>

=over

=item $name

the name of the response header

=item $date

the additional header value

=back

=cut

sub addDateHeader {
    my $self = shift;
    my $name = shift;
    my $value = shift;

    return 1 if $self->isCommitted();
    return 1 if $self->isIncluded();

    $self->addHeader($name, $value);

    return 1;
}

=pod

=item setDateHeader($name, $date)

Set the date value for the named response header.

B<Parameters:>

=over

=item $name

the name of the header

=item $date

the header value

=back

=cut

sub setDateHeader {
    my $self = shift;
    my $name = shift;
    my $value = shift;

    return 1 if $self->isCommitted();
    return 1 if $self->isIncluded();

    $self->setHeader($name, $value);

    return 1;
}

=pod

=item addHeader($name, $value)

Add a value for the named response header.

B<Parameters:>

=over

=item $name

the name of the response header

=item $value

the additional header value

=back

=cut

sub addHeader {
    my $self = shift;
    my $name = shift;
    my $value = shift;

    return 1 if $self->isCommitted();
    return 1 if $self->isIncluded();

    $self->{headers}->push_header($name, $value);

    return 1;
}

=pod

=item getHeader($name)

Return the value for the first occurrence of the named response
header. For all values, use C<getHeaderValues()>.

B<Parameters:>

=over

=item $name

the header name

=back

=cut

sub getHeader {
    my $self = shift;
    my $name = shift;

    return $self->getHeaderValues($name)->[0];
}

=pod

=item getHeaderNames()

Return a list of all the header names set for this Response.

=cut

sub getHeaderNames {
    my $self = shift;

    my %names;
    $self->{headers}->scan(sub { $names{$_[0]} = 1 });

    my @names = keys %names;

    return wantarray ? @names : \@names;
}

=pod

=item getHeaderValues($name)

Return the list of values for the named response header.

B<Parameters:>

=over

=item $name

the header name

=back

=cut

sub getHeaderValues {
    my $self = shift;
    my $name = shift;

    my @vals = $self->{headers}->header($name);

    return wantarray ? @vals : \@vals;
}

=item setHeader($name, $value)

Set the value for the named response header.

B<Parameters:>

=over

=item $name

the name of the response header

=item $value

the header value

=back

=cut

sub setHeader {
    my $self = shift;
    my $name = shift;
    my $value = shift;

    return 1 if $self->isCommitted();
    return 1 if $self->isIncluded();

    my $match = lc $name;
    if ($match eq 'content-type') {
        $self->setContentLength($value);
    } elsif ($match eq 'content-length') {
        $self->setContentType($value);
    } else {
        $self->{headers}->header($name, $value);
    }

    return 1;
}

=pod

=item clearHeaders()

Clear the set of headers for this Response;

=cut

sub clearHeaders {
    my $self = shift;

    $self->{headers}->scan(sub {
                               # superclass takes care of these
                               next if (lc $_[0] eq 'content-type' ||
                                        lc $_[0] eq 'content-length');
                               $self->{headers}->remove_header($_[0]);
                           });

    return 1;
}

=pod

=item setLocale($loc)

Set the locale for this Response. The character encoding for this
Response will be set to the encoding specified by the locale, and the
I<Content-Language> header will be set to the language specified by
the locale.

B<Parameters:>

=over

=item $loc

the locale for the response

=back

=cut

sub setLocale {
    my $self = shift;
    my $locale = shift;

    $self->SUPER::setLocale($locale);

    if ($self->{locale}) {
        # XXX: set content-language header
    }

    return 1;
  }

=pod

=pod

=item getMessage()

Return the status message for this Response.

=cut

sub getMessage {
    my $self = shift;

    return $self->{message};
}

=pod

=item getStatus()

Return the HTTP status code for this Response.

=cut

sub getStatus {
    my $self = shift;

    return $self->{status};
}

=pod

=item setStatus($code)

Set the status code for this response.

B<Parameters:>

=over

=item $code

the HTTP status code

=back

=cut

sub setStatus {
    my $self = shift;
    my $status = shift;

    return 1 if $self->isIncluded();

    $self->{status} = $status;
    $self->{message} = $self->getStatusMessage($status);

    return 1;
}

=pod

=back

=head1 PUBLIC METHODS

=over

=item containsHeader($name)

Return a boolean value indicating whether or not the named response
header has already been set.

B<Parameters:>

=over

=item $name

the name of the header

=back

=cut

sub containsHeader {
    my $self = shift;
    my $name = shift;

    return defined $self->getHeader($name);
}

=pod

=item encodeRedirectURL($url)

Encode the session ID for this Response into the specified redirect
URL, if necessary.

B<Parameters:>

=over

=item $url

the url to be encoded

=back

=cut

sub encodeRedirectURL {
    my $self = shift;
    my $url = shift;

    if ($self->isEncodeable($self->toAbsolute($url))) {
        my $freq = $self->{request}->getRequest();
        $url = $self->toEncoded($url, $freq->getSession()->getId());
    }

    return $url;
}

=pod

=item encodeURL($url)

Encode the session ID for this Response into the specified URL, if
necessary.

B<Parameters:>

=over

=item $url

the url to be encoded

=back

=cut

sub encodeURL {
    my $self = shift;
    my $url = shift;

    if ($self->isEncodeable($self->toAbsolute($url))) {
        my $freq = $self->{request}->getRequest();
        $url = $self->toEncoded($url, $freq->getSession()->getId());
    }

    return $url;
}

=pod

=item finishResponse()

Perform whatever actions are required to flush and close the output
handle or writer, including sending headers if the response is not
already committed.

B<Throws:>

=over

=item Servlet::Util::IOException

if an input or output error occurs

=back

=cut

sub finishResponse {
    my $self = shift;

    $self->sendHeaders() unless $self->isCommitted();

    return $self->SUPER::finishResponse(@_);
}

=pod

=item flushBuffer()

Force any content in the buffer to be written to the client. Headers
are automatically sent and the response is committed on the first
invocation of this method.

B<Throws:>

=over

=item B<Servlet::Util::IOException>

=back

=cut

sub flushBuffer {
    my $self = shift;

    $self->sendHeaders() unless $self->isCommitted();

    return $self->SUPER::flushBuffer(@_);
}

=pod

=item reset()

Clear any data that exists in the content buffer and unsets the
content length and content type, all cookies and headers, and the
status and message.

B<Throws:>

=over

=item B<Servlet::Util::IllegalStateException>

if the response has already been committed

=back

=cut

sub reset {
    my $self = shift;

    $self->SUPER::reset(@_);

    $self->clearHeaders();
    $self->clearCookies();

    my $status = Servlet::Http::HttpServletResponse::SC_OK;
    $self->setStatus($status);

    return 1;
}

=pod

=item sendError($code, [$message])

Send an error response with the specified status and optional message.

B<Parameters:>

=over

=item $code

the error status code

=item $message

the optional descriptive message; if unspecified, the standard message
for the given status code will be used.

=back

B<Throws:>

=over

=item B<Servlet::Util::IOException>

if an input or output exception occurs

=item B<Servlet::Util::IllegalStateException>

if the response has already been committed

=back

=cut

sub sendError {
    my $self = shift;
    my $status = shift;
    my $message = shift;

    if ($self->isCommitted()) {
        my $msg = "sendError: response already committed";
        Servlet::Util::IllegalStateException->throw($msg);
    }

    return 1 if $self->isIncluded();

    $self->setStatus($status);
    $self->{message} = $message if $message;
    $self->setError();

    $self->resetBuffer();

    return 1;
}

=pod

=item sendRedirect($location)

Send a temporary redirect to the specified URL.

B<Parameters:>

=over

=item $location

the redirect location URL

=back

B<Throws:>

=over

=item B<Servlet::Util::IOException>

if an input or output exception occurs

=item B<Servlet::Util::IllegalStateException>

if the response has already been committed

=back

=cut

sub sendRedirect {
    my $self = shift;
    my $location = shift;

    if ($self->isCommitted()) {
        my $msg = "sendRedirect: response already committed";
        Servlet::Util::IllegalStateException->throw($msg);
    }

    return 1 if $self->isIncluded();

    $self->setHeader("Location", $self->toAbsolute($location));

    my $status = Servlet::Http::HttpServletResponse::SC_MOVED_TEMPORARILY;
    $self->setStatus($status);

    return 1;
}

=pod

=back

=head1 PACKAGE METHODS

=over

=item sendHeaders()

Write response headers to the output handle, committing the
response. Usually doesn't need to be called by other classes, but will
be called the first time the buffer is flushed.

=cut

sub sendHeaders {
    my $self = shift;
    my $request = $self->getRequest();

    # send status line
    $self->{handle}->print($request->getProtocol());
    $self->{handle}->print(' ');
    $self->{handle}->print($self->getStatus());
    my $message = $self->getMessage();
    if ($message) {
        $self->{handle}->print(' ');
        $self->{handle}->print($message);
    }
    $self->{handle}->print("\r\n");

    # send main headers
    if ($self->{contentType}) {
        $self->{handle}->print("Content-Type: $self->{contentType}\r\n");
    }

    if ($self->{contentLength} >= 0) {
        $self->{handle}->print("Content-Length: $self->{contentLength}\r\n");
    }

    # send other headers
    for my $name ($self->getHeaderNames()) {
        for my $value ($self->getHeaderValues($name)) {
            $self->{handle}->print("$name: $value\r\n");
        }
    }

    # add session id cookie if necessary
    my $sessionCookie = Wombat::Util::RequestUtil->makeSessionCookie($request);
    $self->addCookie($sessionCookie) if $sessionCookie;

    # send cookies
    for my $cookie ($self->getCookies()) {
        my $name = Wombat::Util::CookieTools->getCookieHeaderName($cookie);
        my $value = Wombat::Util::CookieTools->getCookieHeaderValue($cookie);
        $self->{handle}->print("$name: $value\r\n");
    }

    $self->{handle}->print("\r\n");
    $self->{handle}->flush();

#    Wombat::Globals::DEBUG &&
#        $self->debug("sent headers");

    unless ($self->{committed}) {
        $self->{committed} = 1;

#        Wombat::Globals::DEBUG &&
#            $self->debug("committed response");
    }

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

    $self->SUPER::recycle($facade);

    $self->{cookies} = [];
    $self->{headers} = HTTP::Headers->new();

    my $status = Servlet::Http::HttpServletResponse::SC_OK;
    $self->{status} = $status;
    $self->{message} = $self->getStatusMessage($status);

    $self->{facade} = $facade ||
        Wombat::Connector::HttpResponseFacade->new($self);

    return 1;
}

# private

sub getStatusMessage {
    my $self = shift;
    my $status = shift;

    return STATUS_MESSAGES->{$status};
}

sub isEncodeable {
    my $self = shift;
    my $location = shift;

    return undef unless $location;

    # is this an intra-document reference?
    return undef if $location =~ m|^\#|;

    # is there a valid session that does not use cookies?
    my $freq = $self->{request}->getRequest();
    return undef if $freq->isRequestedSessionIdFromCookie();

    my $session = $freq->getSession();
    return undef unless $session;

    # does the url match down to the context path?
    my $abs = $self->toAbsolute($location);

    my $uriScheme = $abs->scheme() || '';
    return undef unless lc $freq->getScheme() eq lc $uriScheme;

    my $uriHost = $abs->host() || '';
    return undef unless lc $freq->getServerName() eq lc $uriHost;

    my $serverPort = $freq->getServerPort();
    $serverPort ||= $freq->isSecure() ? 443 : 80;
    my $uriPort = $abs->port() || -1;
    return undef unless $serverPort == $uriPort;

    my $contextPath = $self->{application}->getPath();
    if ($contextPath) {
        my $uriPath = $abs->path() || '';
        return undef unless $uriPath =~ m|^$contextPath|;
    }

    return 1;
}

sub toAbsolute {
    my $self = shift;
    my $location = shift;

    return undef unless $location;

    my $abs = URI->new_abs($location, $self->getRequest()->getRequestURL());
    Servlet::Util::IllegalArgumentException->throw($location) unless $abs;

    return $abs;
}

sub toEncoded {
    my $self = shift;
    my $url = shift;
    my $id = shift;

    return $url unless $url && defined $id;

    my ($path, $query) = split /\?/, $url;

    my $new = join('?', $path,
                   (join '=', Wombat::Globals::SESSION_PARAMETER_NAME, $id));

    $new = join '&', $new, $query if defined $query;

    return $new;
}

=pod

=back

=cut

1;
__END__

=pod

=head1 SEE ALSO

L<Servlet::ServletResponse>,
L<Servlet::Http::Cookie>,
L<Servlet::Util::Exception>,
L<Wombat::HttpResponse>,
L<Wombat::Connector::ResponseBase>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
