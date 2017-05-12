# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::ServletRequest;

$VERSION = 0;

1;
__END__

=pod

=head1 NAME

Servlet::ServletRequest - servlet request interface

=head1 SYNOPSIS

  for my $name ($request->getAttributeNames()) {
      my $val = $request->getAttribute($name);
      $request->removeAttribute($name);
      # or
      $request->setAttribute($name, $newValue);
  }

  my $encoding = $request->getCharacterEncoding();
  $request->setCharacterEncoding($newEncoding);

  my $length = $request->getContentLength();

  my $type = $request->getContentType();

  # gets request body as binary data
  my $input = $request->getInputHandle();

  # gets preferred locale
  my $locale = $request->getLocale();

  # gets all locales in descending order of preference
  my @locales = $request->getLocales();

  my %paramMap = $request->getParameterMap();
  for my $name ($request->getParameterNames()) {
      my $val = $request->getParameter($name);
      # or
      my @vals = $request->getParameterValues($name);
  }

  my $protocol = $request->getProtocol();

  # gets request body as character data, converted from bytes using
  # the request's character encoding
  my $reader = $request->getReader();

  my $addr = $request->getRemoteAddr();

  my $host = $request->getRemoteHost();

  # get a request dispatcher in order to do an include or forward
  my $dispatcher = $request->getRequestDispatcher($path);

  my $scheme = $request->getScheme();

  my $server = $request->getServerName();

  my $port = $request->getServerPort();

  my $flag = $request->isSecure();

=head1 DESCRIPTION

This interface defines an object that provides client request
information to a servlet. The servlet container creates a request
object and passes it as an argument to the servlet's C<service()>
method.

A B<Servlet::ServletRequest> object provides data including parameter
name and values, attributes, and an input handle. Interfaces that
extend ServletRequest can provide additional protocol-specific data
(for example, HTTP data is provided by
B<Servlet::Http::HttpServletRequest>.

=head1 METHODS

=over

=item getAttribute($name)

Returns the value of the named attribute, or I<undef> if no attribute
of the given name exists.

Attributes can be set two ways. The servlet container may set
attributes to make available custom information about a request. For
example, for requests made using HTTPS, the attribute
I<Servlet::Request::X509Certificate> can be used to retrieve
information on the certificate of the client. Attributes can also be
set programatically using C<setAttribute()>. This allows information
to be embedded into a request before a B<Servlet::RequestDispatcher>
call.

Attribute names should follow the same convention as package
names. The Servlet API specification reserves names matching
I<main::*>, I<CORE::*>, I<UNIVERSAL::*>, and any other standard
reserved package names.

B<Parameters:>

=over

=item I<$name>

The name of the attribute

=back

=item getAttributeNames()

Returns an array containing the names of the attributes available to
this request, or an empty array if the request has no attributes
available to it.

=item getCharacterEncoding()

Returns the name of the character encoding used in the body of this
request, or I<undef> if the request does not specify a character
encoding.

=item getContentLength()

Returns the length, in bytes, of the request body and made available
by the input handle, or I<undef> if the length is not known. For HTTP
servlets, same as the value of the CGI variable I<CONTENT_LENGTH>.

=item getContentType()

Returns the MIME type of the body of the request, or I<undef> if the
type is not known. For HTTP servlets, same as the value of the CGI
variable I<CONTENT_TYPE>.

=item getInputHandle()

Retrieves the body of the request as binary data using a
B<IO::Handle>. Either this method or C<getReader()> may be called to
read the body, not both.

B<Throws:>

=over

=item B<Servlet::Util::IllegalStateException>

if the C<getReader()> method has already been called for this request

=item B<Servlet::Util::IOException>

if an input or output exception occurred

=back

=item getLocale()

Returns the preferred locale that the client will accept content in,
based on the I<Accept-Language> header. If the client request doesn't
provide an I<Accept-Language> header, this method returns the default
locale for the server.

=item getLocales()

Returns an array of locales indicating in decreasing order of
preference the locales that are acceptable to the client based on the
I<Accept-Language> header. If the client request doesn't provde an
I<Accept-Language> header, this method returns an array containing one
locale, the default locale for the server.

=item getParameter($name)

Returns the value of a request parameter, or I<undef> if the parameter
does not exist. Request parameters are extra information sent with the
request. For HTTP servlets, parameters are contained in the query
string or posted form data.

You should only use this method when you are sure the parameter has
only one value. If the parameter might have more than one value, use
C<getParameterValues()>.

If you use this method with a multivalued parameter, the value
returned is equal to the first value in the array returned by
C<getParameterValues()>.

If the parameter data was sent in the request body, such as occurs
with an HTTP POST request, then reading the body directly via
C<getInputHandle()> or C<getReader()> can interfere with the execution
of this method.

B<Parameters:>

=over

=item I<$name>

The name of the parameter

=back

=item getParameterMap()

Returns a hash of the parameters of this request. The keys of the hash
are the parameter names, and the values of the hash are arrays of
parameter values.

See C<getParameter()> for more information about parameters and usage.

=item getParameterNames()

Returns an array containing the names of the parameters contained in
this request. If the request has no parameters, the array is empty.

See C<getParameter()> for more information about parameters and usage.

=item getParameterValues($name)

Returns an array containing all of the values of the given request
parameter, or I<undef> if the parameter does not exist.

If the parameter has a single value, the array has a length of 1. If
the parameter has no value, the array is empty.

See C<getParameter()> for more information about parameters and usage.

B<Parameters:>

=over

=item I<$name>

The name of the parameter

=back

=item getProtocol()

Returns the name and version of the protocol the request uses in the
form I<protocol/majorVersion.minorVersion>, for example, HTTP/1.1. For
HTTP servlets, the value returned is the same as the value of the CGI
variable I<SERVER_PROTOCOL>.

=item getReader()

Retrieves the body of the request as character data using a
B<XXX>. The reader translates the character data according to the
character encoding used on the body. Either this method or
C<getInputHandle()> may be called to read the body, not both.

B<Throws:>

=over

=item B<Servlet::Util::UnsupportedEncodingException>

if the character encoding used is not supported and the text cannot be
decoded

=item B<Servlet::Util::IllegalStateException>

if the C<getInputHandle()> method has already been called for this
request

=item B<Servlet::Util::IOException>

if an input or output exception occurred

=back

=item getRemoteAddr()

Returns the Internet Protocol (IP) address of the client that sent the
request. For HTTP servlets, same as the value of the CGI variable
I<REMOTE_ADDR>.

=item getRemoteHost()

Returns the fully qualified name of the client that sent the request,
or the IP address of the client if the name cannot be determined. For
HTTP servlets, same as the value of the CGI variable I<REMOTE_HOST>.

=item getRequestDispatcher($path)

Returns a B<Servlet::RequestDispatcher> object that acts as a wrapper
for the resource located at the given path. The object can be used to
forward a request to the resource or to include the resource in a
response. The resource can be dynamic or static.

The pathname specified may be relative, although it cannot extend
outside the current servlet context. If the path begins with a "/", it
is interpreted as relative to the current context root. This method
returns I<undef> if the servlet cannot return a dispatcher.

The difference between this method and the one provided by
B<Servlet::ServletContext> is that this method can take a relative
path.

B<Parameters:>

=over

=item I<$path>

The path to the resource

=back

=item getScheme()

Returns the name of th scheme used to make this request, for example,
I<http>, I<https>, or I<ftp>. Different schemes have different rules
for constructing URLs, as noted in RFC 1738.

=item getServerName()

Returns the host name of the server that received the request. For
HTTP servlets, same as the value of the CGI variable I<SERVER_NAME>.

=item getServerPort()

Returns the port number on which this request was received. For HTTP
servlets, same as the value of the CGI variable I<SERVER_PORT>.

=item isSecure()

Returns a boolean indicating whether this request was made using a
secure channel, such as HTTPS.

=item removeAttribute($name)

Removes an attribute from this request. This method is not generally
needed as attributes only persist as long as the request is being
handled.

See C<getAttribute()> for information about allowable attribute names.

B<Parameters:>

=over

=item I<$name>

The name of the attribute to remove

=back

=item setAttribute($name, $object)

Stores an attribute in this request. Attributes are reset between
requests. This method is most often used in conjunction with
B<Servlet::RequestDispatcher>.

See C<getAttribute()> for information about allowable attribute names.

B<Parameters:>

=over

=item I<$name>

The name of the attribute to set

=item I<$object>

The object to be stored. Can be a scalar or a reference to an
arbitrary data structure.

=back

=item setCharacterEncoding($name)

Overrides the name of the character encoding used for the body of this
request. This method must be called prior to reading request
parameters or reading input using C<getReader()>.

B<Parameters:>

=over

=item I<$name>

The name of the encoding to set

=back

B<Throws:>

=over

=item B<Servlet::Util::UnsupportedEncodingException>

if this is not a valid encoding

=back

=back

=head1 SEE ALSO

L<IO::Handle>,
L<Servlet::RequestDispatcher>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
