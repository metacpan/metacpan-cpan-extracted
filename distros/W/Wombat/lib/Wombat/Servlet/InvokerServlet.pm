# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Servlet::InvokerServlet;

=pod

=head1 NAME

Wombat::Servlet::InvokerServlet - servlet that invokes other servlets

=head1 DESCRIPTION

The default servlet-invoking servlet for most web applications, used
to serve requests to servlets that have not been registered in the web
application deployment descriptor.

=cut

use base qw(Wombat::ContainerServlet Servlet::Http::HttpServlet);
use fields qw(application wrapper);
use strict;
use warnings;

use Servlet::UnavailableException ();

=pod

=head1 CONSTRUCTOR

=over

=item new()

Create and return an instance, initializing fields to default values.

=back

=cut

sub new {
    my $self = shift;

    $self = fields::new($self) unless ref $self;
    $self->SUPER::new();

    $self->{application} = undef;
    $self->{wrapper} = undef;

    return $self;
}

=pod

=head1 ACCESSOR METHODS

=over

=item getWrapper()

Return the Wrapper that wraps this Servlet.

=cut

sub getWrapper {
    my $self = shift;

    return $self->{wrapper};
}

=pod

=item setWrapper($wrapper)

Set the Wrapper that wraps this Servlet.

B<Parameters:>

=over

=item $wrapper

the B<Wombat::Core::Wrapper> that wraps this Servlet

=back

=cut

sub setWrapper {
    my $self = shift;
    my $wrapper = shift;

    $self->{wrapper} = $wrapper;
    $self->{application} = $wrapper->getParent() if $wrapper;

    return 1;
}

=pod

=back

=head1 PUBLIC METHODS

=over

=item doDelete($request, $response)

Process a DELETE request for the specified resource.

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

=cut

sub doDelete {
    my $self = shift;
    my $request = shift;
    my $response = shift;

    return $self->serveRequest($request, $response);
}

=pod

=item doGet($request, $response)

Process a GET request for the specified resource.

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

=cut

sub doGet {
    my $self = shift;
    my $request = shift;
    my $response = shift;

    return $self->serveRequest($request, $response);
}

=pod

=item doHead($request, $response)

Process a HEAD request for the specified resource.

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

=cut

sub doHead {
    my $self = shift;
    my $request = shift;
    my $response = shift;

    return $self->serveRequest($request, $response);
}

=pod

=item doPost($request, $response)

Process a POST request for the specified resoruce.

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

=cut

sub doPost {
    my $self = shift;
    my $request = shift;
    my $response = shift;

    return $self->serveRequest($request, $response);
}

=pod

=item doPut($request, $response)

Process a PUT request for the specified resource.

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

=cut

sub doPut {
    my $self = shift;
    my $request = shift;
    my $response = shift;

    return $self->serveRequest($request, $response);
}

=pod

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

=cut

sub init {
    my $self = shift;
    my $servletConfig = shift;

    unless ($self->{wrapper} && $self->{application} ) {
        Servlet::UnavailableException->throw("init: no wrapper");
    }

    $self->SUPER::init($servletConfig);

    return 1;
}

# private methods

sub serveRequest {
    my $self = shift;
    my $request = shift;
    my $response = shift;

    # XXX: account for includes

    # servlet name or class is in the path info
    my $pathInfo = $request->getPathInfo();
    unless ($pathInfo) {
#        Wombat::Globals::DEBUG &&
#            $self->debug(sprintf("no path info for %s",
#                                 $request->getRequestURI()));

        my $status = Servlet::Http::HttpServletResponse::SC_NOT_FOUND;
        $response->sendError($status);

        return 1;
    }

    # pathInfo is of the form '/SnoopServlet' or
    # '/Wombat::Servlet::SnoopServlet'
    my $class;
    (undef, $class, $pathInfo) = split /\//, $pathInfo, 3;
    $pathInfo ||= '';

    my $name = "INVOKED::$class";
    my $pattern = join '/', $request->getServletPath(), $class, '*';

    # does the named servlet already exist?
    my $wrapper = $self->{application}->getChild($class);
    if ($wrapper) {
        $name = $wrapper->getName() || $class;
        $self->{application}->addServletMapping($pattern, $name);

#        Wombat::Globals::DEBUG &&
#            $self->debug("added servlet mapping for $pattern to name $name");
    } else {
        # create and install a new wrapper
        eval {
            $wrapper = $self->{application}->createWrapper();
            $wrapper->setName($name);
            $wrapper->setLoadOnStartup(1);
            $wrapper->setServletClass($class);

            $self->{application}->addChild($wrapper);
            $self->{application}->addServletMapping($pattern, $name);

#            Wombat::Globals::DEBUG &&
#                $self->debug("added servlet mapping for $pattern to class $name");
        };
        if ($@) {
            $self->log("failed to create wrapper for $name", $@, 'ERROR');

            my $status = Servlet::Http::HttpServletResponse::SC_NOT_FOUND;
            $response->sendError($status);

            return 1;
        }

        # ensure the instance can be allocated and deallocated
        eval {
            my $instance = $wrapper->allocate();
            $wrapper->deallocate($instance);
        };
        if ($@) {
            my $e = $@;

            $self->{application}->removeServletMapping($pattern);
            $self->{application}->removeChild($wrapper);

#            Wombat::Globals::DEBUG &&
#                $self->debug("removed servlet mapping for $pattern");

            my $status;
            if ($e->isa('Servlet::ServletException')) {
                my $root = $e->getRootCause();
                if ($root && $root =~ /^Can't locate/) {
                    $status =
                        Servlet::Http::HttpServletResponse::SC_NOT_FOUND;
                    $response->sendError($status);
                }
            }

            unless ($status) {
                # rethrow the exception so that the container will
                # serve an error page containing an exception message
                $e->rethrow() if ref $e;
                Servlet::ServletException->throw($@);
            }

            return 1;
        }
    }

    my $path = join '/', $request->getServletPath(), $class, $pathInfo;
    my $dispatcher = $self->getServletContext()->getRequestDispatcher($path);
    return $dispatcher->forward($request, $response);
}

sub debug {
    my $self = shift;
    my $msg = shift;

    return $self->getWrapper()->log($msg, undef, 'DEBUG');
}

1;
__END__

=back

=head1 SEE ALSO

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut


