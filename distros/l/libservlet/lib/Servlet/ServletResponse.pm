# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::ServletResponse;

$VERSION = 0;

1;
__END__

=pod

=head1 NAME

Servlet::ServletResponse - servlet response interface

=head1 SYNOPSIS

  $response->flushBuffer();

  my $size = $response->getBufferSize();

  my $encoding = $response->getCharacterEncoding();

  my $locale = $response->getLocale();

  my $output = $response->getOutputHandle();

  my $writer = $response->getWriter();

  my $flag = $response->isCommitted();

  $response->reset();

  $response->resetBuffer();

  $response->setBufferSize($size);

  $response->setContentLength($length);

  $response->setContentType($type);

  $response->setLocale($locale);

=head1 DESCRIPTION

This interface defines an object that assists a servlet in sending a
response to the client. The servlet container creates the object and
passes it as an argument to the servlet's C<service()> method.

=head1 METHODS

=over

=item flushBuffer()

Forces any content in the buffer to be written to the client. A call
to this method automatically commits the resopnse, meaning the status
code and headers will be written.

B<Throws:>

=over

=item B<Servlet::Util::IOException>

=back

=item getBufferSize()

Returns the actual buffer size used for the response, or 0 if no
buffering is used.

=item getCharacterEncoding()

Returns the name of the character encoding used in the body of this
response. If not charset has been assigned, it is implicitly set to
I<ISO-8859-1>.

=item getLocale()

Returns the locale assigned to the response.

=item getOutputHandle()

Returns a B<IO::Handle> suitable for writing binary data in the
response. The servlet container does not encode the binary data.

Calling C<flush()> commits the response.

Either this method or C<getWriter()> may be called to write the body,
not both.

B<Throws:>

=over

=item B<Servlet::Util::IllegalStateException>

if the C<getWriter()> method has already been called for this response

=item B<Servlet::Util::IOException>

if an input or output exception occurred

=back

=item getWriter()

Returns a B<XXX> object that can send character text to the
client. The character encoding used is the one specified in the
I<charset> parameter of C<setContentType()>, which must be called
before calling this metod for the charset to take effect.

If necessary, the content type of the response is modified to reflect
the character encoding used.

Calling C<flush()> commits the response.

Either this method or C<getOutputHandle()> may be called to write the
body, not both.

B<Throws:>

=over

=item B<Servlet::Util::UnsupportedEncodingException>

if the charset specified in C<setContentType()> cannot be used

=item B<Servlet::Util::IllegalStateException>

if the C<getOutputHandle()> method has already been called for this
request

=item B<Servlet::Util::IOException>

if an input or output exception occurred

=back

=item isCommitted()

Returns a boolean indicating if the response has been committed. A
committed response has already had its status code and headers
written.

=item reset()

Clears any data that exists in the buuffer as well as the status code
and headers.

B<Throws:>

=over

=item B<Servlet::Util::IllegalStateException>

if the response has already been committed

=back

=item resetBuffer()

Clears the content of the underlying buffer in the response without
clearing headers or status code.

B<Throws:>

=over

=item B<Servlet::Util::IllegalStateException>

if the response has already been committed

=back

=item setBufferSize($size)

Sets the preferred buffer size for the body of the response. The
servlet container will use a buffer at least as large as the size
requested. The actual buffer size can be found using
C<getBufferSize()>.

A larger buffer allows more content to be written before anything is
actually sent, thus providing the servlet with more time to set
appropriate status codes and headers. A smaller buffer decreases
server memory load and allows the client to start receiving data more
quickly.

This method must be called before any response body content is written.

B<Parameters:>

=over

=item I<$size>

The preferred buffer size

=back

B<Throws:>

=over

=item B<Servlet::Util::IllegalStateException>

if content has been written to the buffer

=back

=item setContentLength($len)

Sets the length of the content body in the response. In HTTP servlets,
this method sets the HTTP I<Content-Length> header.

B<Parameters:>

=over

=item I<$len>

The length of the content being returned to the client

=back

=item setContentLength($len)

Sets the length of the content body in the response. In HTTP servlets,
this method sets the HTTP I<Content-Length> header.

B<Parameters:>

=over

=item I<$len>

The length of the content being returned to the client

=back

=item setContentType($type)

Sets the content type of the response. The content type may include
the type of character encoding used, for example I<text/html;
charset=ISO-8859-4>.

If calling C<getWriter()>, this method should be called first.

B<Parameters:>

=over

=item I<$type>

The MIME type of the content

=back

=item setLocale($loc)

Sets the locale of the response, setting the headers (including the
I<charset> attribute of the I<Content-Type>) as appropriate.

This method should be called before a call to C<getWriter()>.

By default, the response locale is the default locale for the server.

B<Parameters:>

=over

=item I<$loc>

The locale of the response

=back

=back

=head1 SEE ALSO

L<IO::Handle>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
