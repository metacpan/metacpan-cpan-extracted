# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::Http::HttpServlet;

use base qw(Servlet::GenericServlet);
use strict;
use warnings;

use Servlet::ServletException ();
use Servlet::Http::HttpServletResponse ();

use constant METHOD_DELETE => 'DELETE';
use constant METHOD_HEAD => 'HEAD';
use constant METHOD_GET => 'GET';
use constant METHOD_OPTIONS => 'OPTIONS';
use constant METHOD_POST => 'POST';
use constant METHOD_PUT => 'PUT';
use constant METHOD_TRACE => 'TRACE';

use constant HEADER_IFMODSINCE => 'If-Modified-Since';
use constant HEADER_LASTMOD => 'Last-Modified';

sub new {
    my $self = shift;

    $self = fields::new($self) unless ref $self;
    $self->SUPER::new(@_);

    return $self;
}

sub doDelete {
    my $self = shift;
    my $request = shift;
    my $response = shift;

    my $msg = 'HTTP method DELETE is not supported';
    my $protocol = $request->getProtocol();
    my $code;
    if ($protocol =~ /1\.1$/) {
        $code = Servlet::Http::HttpServletResponse::SC_METHOD_NOT_ALLOWED;
    } else {
        $code = Servlet::Http::HttpServletResponse::SC_BAD_REQUEST;
    }

    $response->sendError($code, $msg);

    return 1;
}

sub doGet {
    my $self = shift;
    my $request = shift;
    my $response = shift;

    my $method = $request->getMethod();
    my $msg = "HTTP method $method is not supported";
    my $protocol = $request->getProtocol();
    my $code;
    if ($protocol =~ /1\.1$/) {
        $code = Servlet::Http::HttpServletResponse::SC_METHOD_NOT_ALLOWED;
    } else {
        $code = Servlet::Http::HttpServletResponse::SC_BAD_REQUEST;
    }

    $response->sendError($code, $msg);

    return 1;
}

sub doHead {
    my $self = shift;
    my $request = shift;
    my $response = shift;

    # use a response wrapper that eats the output handle but sets the
    # content length appropriately

    my $noBodyResponse =
        Servlet::Http::HttpServlet::NoBodyResponse->new($response);

    $self->doGet($request, $noBodyResponse);
    $noBodyResponse->setContentLength();

    return 1;
}

sub doPost {
    my $self = shift;
    my $request = shift;
    my $response = shift;

    my $msg = 'HTTP method POST is not supported';
    my $protocol = $request->getProtocol();
    my $code;
    if ($protocol =~ /1\.1$/) {
        $code = Servlet::Http::HttpServletResponse::SC_METHOD_NOT_ALLOWED;
    } else {
        $code = Servlet::Http::HttpServletResponse::SC_BAD_REQUEST;
    }

    $response->sendError($code, $msg);

    return 1;
}

sub doOptions {
    my $self = shift;
    my $request = shift;
    my $response = shift;

    my @meth;

    # XXX: shouldn't be using can(), since it traverses the
    # inheritance tree, and we just want to examine the classes
    # that are descendents of HttpServlet

    if ($self->can('doDelete')) {
        push @meth, qw(DELETE);
    }
    if ($self->can('doGet')) {
        push @meth, qw(GET HEAD);
    }
    if ($self->can('doOptions')) {
        push @meth, qw(OPTIONS);
    }
    if ($self->can('doPost')) {
        push @meth, qw(POST);
    }
    if ($self->can('doPut')) {
        push @meth, qw(PUT);
    }
    if ($self->can('doTrace')) {
        push @meth, qw(TRACE);
    }

    $response->setHeader('Allow', join(', ', @meth));

    return 1;
}

sub doPut {
    my $self = shift;
    my $request = shift;
    my $response = shift;

    my $msg = 'HTTP method PUT is not supported';
    my $protocol = $request->getProtocol();
    my $code;
    if ($protocol =~ /1\.1$/) {
        $code = Servlet::Http::HttpServletResponse::SC_METHOD_NOT_ALLOWED;
    } else {
        $code = Servlet::Http::HttpServletResponse::SC_BAD_REQUEST;
    }

    $response->sendError($code, $msg);

    return 1;
}

sub doTrace {
    my $self = shift;
    my $request = shift;
    my $response = shift;

    my $str = sprintf("TRACE %s %s\r\n",
                      $request->getRequestURI(),
                      $request->getProtocol());

    for my $name ($request->getHeaderNames()) {
        $str .= sprintf ("%s: %s\r\n", $name, $request->getHeader($name));
    }

    $response->setContentType('message/http');
    $response->setContentLength(length($str));
    my $out = $response->getOutputHandle();
    $out->print($str);
    $out->close();

    return 1;
}

sub getLastModified {
    my $self = shift;
    my $request = shift;

    return -1;
}

sub service {
    my $self = shift;
    my $request = shift;
    my $response = shift;

    unless ($request->isa('Servlet::Http::HttpServletRequest') &&
            $response->isa('Servlet::Http::HttpServletResponse')) {
        my $msg = 'non-HTTP request or response';
        Servlet::ServletException->throw($msg);
    }

    my $method = $request->getMethod();

    if ($method eq METHOD_DELETE) {
        $self->doDelete($request, $response);
    } elsif ($method eq METHOD_GET) {
        my $lastmod = $self->getLastModified($request);
        if ($lastmod == -1) {
            $self->doGet($request, $response);
        } else {
            my $ifmodsince = $request->getDateHeader(HEADER_IFMODSINCE);
            if ($ifmodsince < ($lastmod / 1000 * 1000)) {
                $self->maybeSetLastModified($response, $lastmod);
                $self->doGet($request, $response);
            } else {
                my $code = Servlet::Http::HttpServletResponse::SC_NOT_MODIFIED;
                $response->setStatus($code);
            }
        }
    } elsif ($method eq METHOD_HEAD) {
        my $lastmod = $self->getLastModified($request);
        $self->maybeSetLastModified($response, $lastmod);
        $self->doHead($request, $response);
    } elsif ($method eq METHOD_OPTIONS) {
        $self->doOptions($request, $response);
    } elsif ($method eq METHOD_POST) {
        $self->doPost($request, $response);
    } elsif ($method eq METHOD_PUT) {
        $self->doPut($request, $response);
    } elsif ($method eq METHOD_TRACE) {
        $self->doTrace($request, $response);
    } else {
        my $msg = "HTTP method $method is not supported";
        my $code = Servlet::Http::HttpServletResponse::SC_NOT_IMPLEMENTED;
        $response->sendError($code, $msg);
    }

    return 1;
}

sub maybeSetLastModified {
    my $self = shift;
    my $response = shift;
    my $lastmod = shift;

    # don't set the header if it's already been set
    return 1 if $response->containsHeader(HEADER_LASTMOD);

    $response->setDateHeader(HEADER_LASTMOD, $lastmod) if $lastmod >= 0;

    return 1;
}

1;

package Servlet::Http::HttpServlet::NoBodyResponse;

use base qw(Servlet::Http::HttpServletResponseWrapper);
use fields qw(output writer didSetContentLength);
use strict;
use warnings;

# simple response wrapper class that gets content length from output
# handle class

sub new {
    my $self = shift;

    $self = fields::new($self) unless ref $self;
    $self->SUPER::new(@_);

    $self->{output} = Servlet::Http::HttpServlet::NoBodyOutputHandle->new();
    $self->{writer} = undef;
    $self->{didSetContentLength} = undef;

    return $self;
}

sub setContentLength {
    my $self = shift;
    my $len = shift;

    if ($len) {
        $self->{response}->setContentLength($len);
        $self->{didSetContentLength} = 1;
    } else {
        unless ($self->{didSetContentLength}) {
            my $len = $self->{output}->getContentLength();
            $self->{response}->setContentLength($len);
        }
    }

    return 1;
}

sub getOutputHandle {
    my $self = shift;

    return $self->{output};
}

sub getWriter {
    my $self = shift;

    unless ($self->{writer}) {
        # XXX
        return $self->{output};
    }

    return $self->{writer};
}

1;

package Servlet::Http::HttpServlet::NoBodyOutputHandle;

use base qw(IO::Handle);
use fields qw(contentLength);
use strict;
use warnings;

# simple output handle class that eats the output data but calculates
# content length correctly

sub new {
    my $self = shift;

    $self = $self->SUPER::new(@_);
    ${*self}{servlet_http_httpservlet_nobodyoutputhandle_contentlength} = 0;

    return $self;
}

sub getContentLength {
    my $self = shift;

    return ${*self}{servlet_http_httpservlet_nobodyoutputhandle_contentlength};
}

sub print {
    my $self = shift;

    return $self->write(@_);
}

sub write {
    my $self = shift;
    my $str = shift;
    my $len = shift || length $str;

    ${*self}{servlet_http_httpservlet_nobodyoutputhandle_contentlength} +=
        $len;

    return 1;
}

1;
__END__

=pod

=head1 NAME

Servlet::Http::HttpServlet - HTTP servlet base class

=head1 SYNOPSIS

  $servlet->doDelete($request, $response);

  $servlet->doGet($request, $response);

  $servlet->doHead($request, $response);

  $servlet->doOptions($request, $response);

  $servlet->doPost($request, $response);

  $servlet->doPut($request, $response);

  $servlet->doTrace($request, $response);

  my $time = $servlet->getLastModified($request);

  $servlet->service($request, $response);

=head1 DESCRIPTION

This class acts as a base class for HTTP servlets. Subclasses must
override at least one method, usually one of these:

=over

=item C<doGet()>

if the servlet supports HTTP GET requests

=item C<doPost()>

for HTTP POST requests

=item C<doPut()>

for HTTP PUT requests

=item C<doDelete()>

for HTTP DELETE requests

=item C<init()> and C<destroy()>

to manage resources that are held for the life of the servlet

=item C<getServletInfo()>

which the servlet uses to provide information about itself

=back

There's almost no reason to override the C<service()> method, which
handles standard HTTP requests by dispatching them to the handler
methods for each HTTP request type (the C<doXXX()> methods listed
above).

Likewise, there's almost no reason to override the C<doOptions()> and
C<doTrace()> methods.

Servlets typically run on multithreaded servers, so be aware that a
servlet must handle concurrent requets and be careful to synchronize
access to shared resources. Shared resources include in-memory data
such as instance or class variables and external objects such as
files, database connections, and network connections. See
L<perlthrtut> for more information on handling multiple threads in a
Perl program.

=head1 CONSTRUCTOR

=over

=item new()

Does nothing. All of the servlet initialization is done by the
C<init()> method.

=back

=head1 METHODS

=over

=item doDelete($request, $response)

Called by the server (via the C<service()> method) to allow a servlet
to handle a DELETE request. The DELETE operation allows a client to
remove a document or Web page from the server.

This method does not need to be either safe or idempotent. Operations
requested through DELETE can have side effects for which users can be
held accountable. When using this method, it may be useful to save a
copy of the affected resource in temporary storage.

If the request is incorrectly formatted, the method returns an HTTP
"Bad Request" message.

B<Parameters:>

=over

=item I<$request>

the B<Servlet::Http::HttpServletRequest> object that contains the
client request

=item I<$response>

the B<Servlet::Http::HttpServletResponse> object that contains the
servlet response

=back

B<Throws:>

=over

=item B<Servlet::ServletException>

if the request cannot be handled

=item B<Servlet::Util::IOException>

if an input or output error occurs

=back

=item doGet($request, $response)

Called by the server (via the C<service()> method) to allow a servlet
to handle a GET request.

Overriding this method to support a GET request also automatically
supports an HTTP HEAD request. A HEAD request is a GET request that
returns no body in the response, only the response headers.

When overriding this method, read the request data, write the response
headers, get the response's writer or output handle object, and
finally, write the response data. It's best to include content type
and encoding.

The servlet container must write the headers before committing the
response, because in HTTP the headers must be sent before the response
body.

Where possible, set the content length, to allow the servlet container
to use a persistent connection to return its response to the client,
improving performance. The content length is automatically set if the
entire response fits inside the response buffer.

The GET method should be safe, that is, without any side effects for
which users are held responsible. For example, most form queries have
no side effects. If a client request is intended to change stored
data, the request should use some other HTTP method.

The GET method should also be idempotent, meaning that it can be
safely repeated. Sometimes making a method safe also makes it
idempotent. For example, repeating queries is both safe and
idempotent, but buying a product online or modifying data is neither
safe nor idempotent.

If the request is incorrectly formatted, the method returns an HTTP
"Bad Request" message.

B<Parameters:>

=over

=item I<$request>

the B<Servlet::Http::HttpServletRequest> object that contains the
client request

=item I<$response>

the B<Servlet::Http::HttpServletResponse> object that contains the
servlet response

=back

B<Throws:>

=over

=item B<Servlet::ServletException>

if the request cannot be handled

=item B<Servlet::Util::IOException>

if an input or output error occurs

=back

=item doHead($request, $response)

Called by the server (via the C<service()> method) to allow a servlet
to handle a HEAD request. The client sends a HEAD request when it
wants to see only the headers. The HEAD method counts the output bytes
in the response to set the content length accurately.

If you override this method, you can avoide computing the response
body and just set the response ehaders directly to improve
performance. Make sure the method you write is both safe and
idempotent.

If the request is incorrectly formatted, the method returns an HTTP
"Bad Request" message.

B<Parameters:>

=over

=item I<$request>

the B<Servlet::Http::HttpServletRequest> object that contains the
client request

=item I<$response>

the B<Servlet::Http::HttpServletResponse> object that contains the
servlet response

=back

B<Throws:>

=over

=item B<Servlet::ServletException>

if the request cannot be handled

=item B<Servlet::Util::IOException>

if an input or output error occurs

=back

=item doOptions($request, $response)

Called by the server (via the C<service()> method) to allow a servlet
to handle a OPTIONS request. The OPTIONS request determines which HTTP
methods the server supports and returns an appropriate header. For
example, if a servlet overrides C<doGet()>, this method returns the
following header:

  Allow: GET, HEAD, TRACE, OPTIONS

There's no need to override this method unless the servlet implements
new HTTP methods beyond those implemented by HTTP 1.1.

If the request is incorrectly formatted, the method returns an HTTP
"Bad Request" message.

B<Parameters:>

=over

=item I<$request>

the B<Servlet::Http::HttpServletRequest> object that contains the
client request

=item I<$response>

the B<Servlet::Http::HttpServletResponse> object that contains the
servlet response

=back

B<Throws:>

=over

=item B<Servlet::ServletException>

if the request cannot be handled

=item B<Servlet::Util::IOException>

if an input or output error occurs

=back

=item doPost($request, $response)

Called by the server (via the C<service()> method) to allow a servlet
to handle a POST request. The POST method allows the client to send
data of unlimited length to the Web server.

When overriding this method, read the request data, write the response
headers, get the response's writer or output handle object, and
finally, write the response data. It's best to include content type
and encoding.

The servlet container must write the headers before committing the
response, because in HTTP the headers must be sent before the response
body.

Where possible, set the content length, to allow the servlet container
to use a persistent connection to return its response to the client,
improving performance. The content length is automatically set if the
entire response fits inside the response buffer.

When using HTTP 1.1 chunked encoding (which means that the response
has a Transfer-Encoding header), do not set the content length.

This method does not need to be either safe or idempotent. Operations
requested through POST can have side effects for which the user can be
held accountable, for example, updating stored data or buying items
online.

If the request is incorrectly formatted, the method returns an HTTP
"Bad Request" message.

B<Parameters:>

=over

=item I<$request>

the B<Servlet::Http::HttpServletRequest> object that contains the
client request

=item I<$response>

the B<Servlet::Http::HttpServletResponse> object that contains the
servlet response

=back

B<Throws:>

=over

=item B<Servlet::ServletException>

if the request cannot be handled

=item B<Servlet::Util::IOException>

if an input or output error occurs

=back

=item doPut($request, $response)

Called by the server (via the C<service()> method) to allow a servlet
to handle a Put request. The PUT operation allows a client to place a
file on the server and is similar to sending a file by FTP.

When overriding this method, leave intact any content headers sent
with the request (including Content-Length, Content-Type,
Content-Transfer-Encoding, Content-Encoding, Content-Base,
Content-Language, Content-Location, Content-MD5 and Content-Range). If
your method cannot handle a content header, it must issue an error
message (HTTP 501 - Not Implemented) and discard the request. For more
information on HTTP 1.1, see RFC 2068.

This method does not need to be either safe or idempotent. Operations
that it performs can have side effects for which the user can be held
accountable. When using this method, it may be useful to save a copy
of the affected URL in temporary storage.

If the request is incorrectly formatted, the method returns an HTTP
"Bad Request" message.

B<Parameters:>

=over

=item I<$request>

the B<Servlet::Http::HttpServletRequest> object that contains the
client request

=item I<$response>

the B<Servlet::Http::HttpServletResponse> object that contains the
servlet response

=back

B<Throws:>

=over

=item B<Servlet::ServletException>

if the request cannot be handled

=item B<Servlet::Util::IOException>

if an input or output error occurs

=back

=item getLastModified($request)

Returns the time the requested resource was last modified, in
milliseconds since midnight January 1, 1970 GMT. IF the time is
unknown, this method returns a negative number (the default).

Servlets that support HTTP GET requests and can quickly determine
their last modification time should override this method. This makes
browser and proxy caches work more effectively, reducing the load on
server and network resources.

B<Parameters:>

=over

=item I<$request>

the B<Servlet::Http::HttpServletRequest> object that contains the
client request

=back

=item service($request, $response)

Dispatches client requests to the I<doXXX> methods defined in this
class. There's no need to override this method.

B<Parameters:>

=over

=item I<$request>

the B<Servlet::Http::HttpServletRequest> object that contains the
client request

=item I<$response>

the B<Servlet::Http::HttpServletResponse> object that contains the
servlet response

=back

B<Throws:>

=over

=item B<Servlet::ServletException>

if the request cannot be handled

=item B<Servlet::Util::IOException>

if an input or output error occurs

=back

=back

=head1 SEE ALSO

L<Servlet::GenericServlet>,
L<Servlet::Http::HttpServletRequest>,
L<Servlet::Http::HttpServletResponse>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
