# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::ServletContext;

$VERSION = 0;

1;
__END__

=pod

=head1 NAME

Servlet::ServletContext - servlet context interface

=head1 SYNOPSIS

  for my $name ($context->getAttributeNames()) {
      my $value = $context->getAttribute($name);
      $context->removeAttribute($name);
      $cnotext->setAttribute($name, $value);
  }

  my $context = $context->getContext($uripath);

  for my $name ($context->getInitParameterNames()) {
      my $value = $context->getInitParameter($name);
  }

  for my $uripath ($context->getResourcePaths()) {
      my $url = $context->getResource($uripath);
      my $handle = $context->getResourceAsHandle($uripath);
      my $realpath = $context->getRealPath($uripath);
      my $dispatcher = $context->getRequestDispatcher($uripath);
  }

  my $type = $context->getMimeType($file);

  my $dispatcher = $context->getNamedDispatcher($name);

  my $major = $context->getMajorVersion();
  my $minor = $context->getMinorVersion();
  my $info = $context->getServerInfo();
  my $name = $context->getServletContextName();

  $contxt->log($message, $e);

=head1 DESCRIPTION

Defines a set of methods that a servlet uses to communicate with its
servlet container, for example, to get the MIME type of a file,
dispatch requests, or write to a log file.

There is one context per web application per Perl interpreter. A "web
application" is a collection of servlets and content installed under a
specific subset of the server's URL namespace.

In the case of a web application marked "distributed" in its
deployment descriptor, there will be one context instance for each
interpreter. In this situation, the context cannot be used as a
location to share global information (because the information won't
truly be global). Use an external resource like a database instead.

The B<Servlet::ServletContext> object is contained within the
B<Servlet::ServletConfig> object, which the servlet container provides
the servlet when the servlet is initialized.

=head1 METHODS

=over

=item getAttribute($name)

Returns the servlet container attribute with the given name, or
I<undef> if there is no attribute by that name. An attribute allows a
servlet container to give the servlet additional information not
already provided by this interface. See your server documentation for
information about its attributes. A list of supported attributes can
be retrieved using C<getAttributeNames()>.

The attribute is returned as a Perl scalar or reference. Attribute
names should follow the same convention as package names. The Servlet
API specification reserves names matching I<main::*>, I<CORE::*>,
I<UNIVERSAL::*>, and any other standard reserved package names.

B<Parameters:>

=over

=item I<$name>

the name of the attribute

=back

=item getAttributeNames()

Returns an array containing the attribute names available within this
servlet context, or an empty array if no attributes are available for
the context.

=item getContext($uripath)

Returns a B<Servlet::ServletContext> object that corresponds to a
specified URL on the server.

This method allows servlets to gain access to the context for various
parts of the server, and as needed obtain
B<Servlet::RequestDispatcher> objects from the context. The given path
must be absolute (beginning with '/') and is intepreted based on the
server's document root.

In a security conscious environment, the servlet container may return
I<undef> for a given URL.

B<Parameters:>

=over

=item I<$uripath>

the absolute URL of a resource on the server

=back

=item getInitParameter($name)

Returns the vlaue of the named context-wide initialization parameter,
or I<undef> if the parameter does not exist.

This method can make available configuration information useful to an
entire web application. for example, it can provide a webmaster's
email address or the name of a system that holds critical data.

B<Parameters:>

=over

=item I<$name>

the name of the init parameter

=back

=item getInitParameterNames()

Returns an array containing the names of the context's initialization
parameters, or an empty array if the context has no initialization
parameters.

=item getMajorVersion()

Returns the major version of the Servlet API that this servlet
container supports. All implementations that comply with Version 2.3
must have this method return the integer 2.

=item getMimeType($file)

Returns the MIME type of the specified file, or I<undef> if the MIME
type is not known. The MIME type is determined by the configuration of
the servlet container and may be specified in a web application
deployment descriptor. Common MIME types are "text/html" and
"image/gif".

B<Parameters:>

=over

=item I<$file>

the name of a file

=back

=item getMinorVersion()

Returns the minor version of the Servlet API that this servlet
container supports. All implementations that comply with Version 2.3
must have this method return the integer 3.

=item getNamedDispatcher($name)

Returns a B<Servlet::RequestDispatcher> object that acts as a wrapper
for the named servlet, or I<undef> if the context cannot return a
dispatcher object for any reason.

Servlets may be given names via server administration or via a web
appliation deployment descriptor. A servlet instance can determine its
name using C<getServletName()>.

B<Parameters:>

=over

=item I<$name>

the name of a servlet

=back

=item getRealPath($uripath)

Returns the real path for a given virtual path, or I<undef> if the
servlet container cannot translate the virtual path to a real path for
any reason. For example, the path "/index.html" returns the absolute
file path on the server's filesystem that would be served by a request
for "http://host:port/contextPath/index.html", where contextPath is
the context path of this context.

The real path returned will be in a form appropriate to the computer
and operating system on which the servlet container is running,
including the proper path separators.

B<Parameters:>

=over

=item I<$uripath>

the virtual path

=back

=item getRequestDispatcher($uripath)

Returns a B<Servlet::RequestDispatcher> object that acts as a wrapper
for the resource located at the given path, or I<undef> if the context
cannot return a dispatcher. A dispatcher can be used to forward a
request to the resource or to include the resource in a response. The
resource can be dynamic or static.

The uripath must begin with a '/' and is interpreted as relative to
the current context root. Use C<getContext()> to obtain a dispatcher
for resources in foreign contexts.

B<Parameters:>

=over

=item I<$uripath>

the uri path to the resource

=back

=item getResource($uripath)

Returns a URL to the resource that is mapped to a specified uri path,
or I<undef> if no resource is mapped to the uri path. The path must
begin with a '/' and is interpreted as relative to the current context
root.

This method allows the servlet container to make a resource available
to servlets from any source. Resources can be located on a local or
remote file system, in a database, etc.

The servlet container must implement any objects that are necessary to
access the resource.

The resource content is returned directly in an unprocessed form. Use
a B<Servlet::RequestDispatcher> instead to include results of an
execution.

B<Parameters:>

=over

=item I<$uripath>

the uri path to the resource

=back

=item getResourceAsHandle($uripath)

Returns the resource located at the named uri path as an opened
B<IO::Handle>, or I<undef> if no resource exists at the specified
path).

The data in the filehandle can be of any type or length. The uri path
must be specified according to the rules given in C<getResource()>.

Meta-information such as content length and content type that is
available via C<getResource()> is lost when using this method.

The servlet container must implement any objects that are necessary to
access the resource.

B<Parameters:>

=over

=item I<$uripath>

the uri path to the resource

=back

=item getResourcePaths()

Returns an array containing all the paths to resources held in the web
application. All paths begin with '/' and are relative to the root of
the web application.

=item getServerInfo()

Returns the name and version of the servlet container on which the
servlet is running.

The form of the returned string is I<servername/versionnumber>. For
example:

  Wombat/1.0

The servlet container may return other optional information after the
primary string in parentheses. For example:

  Wombat/1.0 (perl 5.6.0; Linux 2.2.18 i686)

=item getServletContextName()

Returns the name of the web application corresponding to this context
as specified in the deployment descriptor for the web appliation.

=item log($message, [$e])

Writes the specified message (and stack trace, if an optional
exception is specified) to the servlet log, prepended by the servlet's
name.

B<Parameters:>

=over

=item I<$message>

the error message

=item I<$e>

an instance of B<Servlet::Util::Exception> (optional)

=back

=item removeAttribute($name)

Removes the attribute with the given name from the servlet
context. After removal, subsequent calls to C<getAttribute()> to
retrieve the attribute's value will return I<undef>.

B<Parameters:>

=over

=item I<$name>

the name of the attribute

=back

=item setAttribute($name, $value)

Binds an object to a given attribute name in the servlet contxt. If
the name specified is already used for an attribute, the old attribute
is removed and the name bound to the new attribute.

See C<getAttribute()> for details on attribute naming.

B<Parameters:>

=over

=item I<$name>

the name of the attribute

=item I<$value>

the attribute to be bound

=back

=back

=head1 SEE ALSO

L<IO::Handle>,
L<Servlet::GenericServlet>,
L<Servlet::RequestDispatcher>,
L<Servlet::ServletConfig>,
L<Servlet::Util::Exception>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
