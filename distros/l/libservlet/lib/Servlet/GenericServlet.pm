# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::GenericServlet;

use fields qw(config);
use strict;
use warnings;

sub new {
    my $self = shift;

    $self = fields::new($self) unless ref $self;

    $self->{config} = undef;

    return $self;
}

sub destroy {
    my $self = shift;

    $self->log('destroy');

    return 1;
}

sub getInitParameter {
    my $self = shift;
    my $name = shift;

    return $self->getServletConfig()->getInitParameter($name);
}

sub getInitParameterNames {
    my $self = shift;

    return $self->getServletConfig()->getInitParameterNames();
}

sub getServletConfig {
    my $self = shift;

    return $self->{config};
}

sub getServletContext {
    my $self = shift;

    return $self->getServletConfig()->getServletContext();
}

sub getServletInfo {
    my $self = shift;

    return '';
}

sub getServletName {
    my $self = shift;

    return $self->getServletConfig()->getServletName();
}

sub init {
    my $self = shift;
    my $config = shift;

    $self->{config} = $config;
    $self->log('init');

    return 1;
}

sub log {
    my $self = shift;
    my $msg = shift || '';
    my $e = shift;

    my $logmsg = sprintf "%s: %s", $self->getServletName(), $msg;
    return $self->getServletContext()->log($logmsg, $e);
}

sub service {
    my $self = shift;
    my $request = shift;
    my $response = shift;

    $self->log('service');

    return 1;
}

1;
__END__

=pod

=head1 NAME

Servlet::GenericServlet - Servlet base class

=head1 SYNOPSIS

  # usually subclasses will be instantiated instead
  my $servlet = Servlet::GenericServlet->new();

  $servlet->init($config);

  for my $name ($getInitParameterNames()) {
      my $value = $servlet->getInitParameter($name);
  }

  my $config = $servlet->getServletConfig();

  my $context = $servlet->getServletContext();

  my $info = $servlet->getServletInfo();

  my $name = $servlet->getServletName();

  $servlet->service($request, $response);

  $servlet->log($message, $e);

  $servlet->destroy();

=head1 DESCRIPTION

Defines a generic, protocol-independent servlet. To write an HTTP
servlet, extend B<Servlet::Http::HttpServlet> instead.

Implements the B<Servlet::Servlet> and B<Servlet::ServletConfig>
interfaces. May be directly extended by a servlet, although it's more
common to extend a protocol-specific subclass.

To write a generic servlet, a developer need only override the
C<service()> method.

=head1 CONSTRUCTOR

=over

=item new()

Does nothing. All of the servlet initialization is done by the
C<init()> method.

=back

=head1 METHODS

=over

=item destroy()

Called by the servlet container to indicate to a servlet that the
servlet is being taken out of service.

=item getInitParameter($name)

Returns the value of the named initialization parameter, or I<undef>
if the parameter does not exists.

This method is supplied for convenience. It gets the value of the
named parameter from the servlet's config object.

B<Parameters:>

=over

=item I<$name>

the name of the parameter

=back

=item getParameterNames()

Returns an array containing the names of the servlet's initialization
parameters, or an empty array if the servlet has no initialization
parameters.

This method is supplied for convenience. It gets the parameter names
from the servlet's config object.

=item getServletConfig()

Returns this servlet's B<Servlet::ServletConfig> object.

=item getServletContext()

Returns the B<Servlet::ServletContext> object representing the web
application in which the servlet is running.

This method is supplied for convenience. It gets the context from the
servlet's config object.

=item getServletInfo()

Returns information about the servlet, such as author, version, and
copyright. By default, this method returns an empty string. Override
this method to have it return a meaningful value.

=item getServletName()

Returns the name of this servlet instance.

=item init([$config])

Called by the servlet container to indicate to a servlet that the
servlet is being placed into service.

This implementation stores the config object it receives from the
servlet container for later use. When overriding this method, make
sure to call

  $self->SUPER::init($config)

B<Parameters:>

=over

=item I<$config>

the B<Servlet::ServletConfig> object that contains configuration
information for this servlet

=back

B<Throws:>

=over

=item B<Servlet::ServletException>

if an exception occurs that interrupts the servlet's normal operation

=back

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

=item service($request, $response)

Called by the servlet container to allow the servlet to respond to a
request. Subclasses should override it.

B<Parameters:>

=over

=item I<$request>

the B<Servlet::ServletRequest> object that contains the client's
request

=item I<$response>

the B<Servlet::ServletResponse> object that contains the servlet's
response

=back

B<Throws:>

=over

=item B<Servlet::ServletException>

if an exception occurs that interferes with the servlet's normal
operation

=item B<Servlet::Util::IOException>

if an input or output exception occurs

=back

=back

=head1 SEE ALSO

L<Servlet::ServletConfig>,
L<Servlet::ServletContext>,
L<Servlet::ServletException>,
L<Servlet::Util::Exception>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
