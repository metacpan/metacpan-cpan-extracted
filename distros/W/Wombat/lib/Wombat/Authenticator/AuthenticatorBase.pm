# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Authenticator::AuthenticatorBase;

=pod

=head1 NAME

Wombat::Authenticator::AuthenticatorBase - internal authenticator base
class

=head1 SYNOPSIS

=head1 DESCRIPTION

Convenience base implementation of B<Wombat::Valve> that enforces the
I<security-constraint> elements in the web application deployment
descriptor. This functionality is implemented as a Valve so that it
can be omitted in environments that do not require these
features. Individual implementations of each supported authentication
method can subclass this base class as required. Subclasses B<MUST>
implement C<authenticate()> and C<getName()>.

When this class is utilized, the Application to which it is attached
must have an associated Realm that can be used for authenticating
users and enumerating the roles to which they have been assigned.

This Valve is only useful when processing HTTP requests. Requests of
any other type will simply be passed through.

=cut

use base qw(Wombat::Authenticator Wombat::Valve::ValveBase);
use fields qw();
use strict;
use warnings;

use Servlet::Http::HttpServletResponse ();
use Servlet::Util::Exception ();
use URI::Escape ();
use Wombat::Globals ();

use constant TRANSPORT_NONE => 'NONE';

=pod

=head1 ACCESSOR METHODS

=over

=item setContainer($container)

Set the Application to which this Authenticator is attached.

B<Parameters:>

=over

=item $container

the B<Wombat::Core::Application> to which this Authenticator is attached

=back

B<Throws:>

=over

=item B<Servlet::Util::IllegalArgumentException>

if the Container is not B<Wombat::Core::Application>

=back

=cut

sub setContainer {
    my $self = shift;
    my $container = shift;

    unless ($container->isa('Wombat::Core::Application')) {
        my $msg = "setContainer: container not Application";
        Servlet::Util::IllegalArgumentException->throw($msg);
    }

    $self->SUPER::setContainer($container);

    return 1;
}

=pod

=back

=head1 PUBLIC METHODS

=over

=item invoke ($request, $response, $context)

Perform request processing as required by this Valve.

B<Parameters>

=over

=item $request

the B<Wombat::Request> to be processed

=item $response

the B<Wombat::Response> to be created

=item $context

the B<Wombat::ValveContext> allowing access to the next Valve in the
Pipeline being processed

=back

B<Throws:>

=over

=item B<Servlet::ServletException>

if a servlet error occurs or is thrown by a subsequently invoked
Valve, Filter or Servlet

=item B<Servlet::Util::IOException>

if an input or output error occurs

=back

=cut

sub invoke {
    my $self = shift;
    my $request = shift;
    my $response = shift;
    my $context = shift;

    # do nothing if the protocol is not HTTP
    unless ($request->isa('Wombat::HttpRequest') &&
            $response->isa('Wombat::HttpResponse')) {
        $context->invokeNext($request, $response);
        return 1;
    }

    my $freq = $request->getRequest();

#    Wombat::Globals::DEBUG &&
#        $self->log(sprintf("Security checking request %s %s",
#                           $freq->getMethod(),
#                           $freq->getRequestURI()),
#                   undef, 'DEBUG');

    my $config = $self->getContainer()->getLoginConfig();

    my $principal = $freq->getUserPrincipal();
    unless ($principal) {
        # check to see if the auth type and principal are cached in
        # the session
        my $session = $self->getSession($request);
        if ($session) {
            $principal = $session->getPrincipal();
            if ($principal) {
                $request->setAuthType($session->getAuthType());
                $request->setUserPrincipal($principal);
            }
        }
    }

    # is this request URI subject to a security constraint?
    my $constraint = $self->findConstraint($request);
    unless ($constraint) {
#$        Wombat::Globals::DEBUG &&
 #           $self->log("No security constraint found", undef, 'DEBUG');
        $context->invokeNext($request, $response);
        return 1;
    }

    # enforce user data constraint for the security constraint
    unless ($self->checkUserData($request, $response, $constraint)) {
#        Wombat::Globals::DEBUG &&
#            $self->log("Failed to satisfy user data constraint",
#                       undef, 'DEBUG');
        return 1;
    }

    my $authConstraint = $constraint->getAuthConstraint();
    if ($authConstraint) {
        # authenticate based upon the specified login configuration
        unless ($self->authenticate($request, $response, $config)) {
#            Wombat::Globals::DEBUG &&
#                $self->log("Failed to authenticate", undef, 'DEBUG');
            return 1;
        }

        # check access based on the specified role
        unless ($self->checkAccess($request, $response, $constraint)) {
#            Wombat::Globals::DEBUG &&
#                $self->log("Failed access check", undef, 'DEBUG');
            return 1;
        }
    }

    $context->invokeNext($request, $response);

    return 1;
}

=pod

=back

=head1 PACKAGE METHODS

=over

=item authenticate($request, $response, $config)

Authenticate the user making this request, based on the specified
login configuration. Return true if any specified constraint has been
satisfied, or false if we have created a response already.

B<Parameters:>

=over

=item $request

the B<Wombat::HttpRequest> being processed

=item $response

the B<Wombat::HttpResponse> being created

=item $constraint

the B<Wombat::Deploy::LoginConfig> describing the authentication
procedure

=back

B<Throws:>

=over

=item B<Servlet::Util::IOException>

if an input or output error occurs

=back

=cut

sub authenticate {}

=pod

=item checkAccess($request, $response, $constraint)

Perform access control based on the specified authorization
constraint. Return true if this constraint was not violated and
processing should continue, of false if we have created a response
already.

B<Parameters:>

=over

=item $request

the B<Wombat::HttpRequest> being processed

=item $response

the B<Wombat::HttpResponse> being created

=item $constraint

the B<Wombat::Deploy::SecurityConstraint> being checked

=back

B<Throws:>

=over

=item B<Servlet::Util::IOException>

if an input or output error occurs

=back

=cut

sub checkAccess {
    my $self = shift;
    my $request = shift;
    my $response = shift;
    my $constraint = shift;

    return 1 unless $constraint;

    my $freq = $request->getRequest();
    my $fres = $request->getResponse();

    my $principal = $freq->getUserPrincipal();
    unless ($principal) {
#        Wombat::Globals::DEBUG &&
#            $self->log("checkAccess: no principal", undef, 'DEBUG');
        my $code =
            Servlet::Http::HttpServletResponse::SC_INTERNAL_SERVER_ERROR;
        $fres->sendError($code);
        return undef;
    }

    my $realm = $self->getContainer()->getRealm();
    my $roles = $constraint->getAuthRoles();
    unless (@$roles) {
        if ($constraint->getAuthConstraint() &&
            !$constraint->getAllRoles()) {
            # there is an auth constraint but no specified roles;
            # means all access is forbidden
            my $code = Servlet::Http::HttpServletResponse::SC_FORBIDDEN;
            $fres->sendError($code);
            return undef;
        }
        # unneccessary to check roles
        return 1;
    }

    for my $role (@$roles) {
        return 1 if $realm->hasRole($principal, $role);
    }

    # principal is not associated with any role in the realm
    my $code = Servlet::Http::HttpServletResponse::SC_FORBIDDEN;
    $fres->sendError($code);
    return undef;
}

=pod

=item checkUserData($request, $response, $constraint)

Enforce any user data constraint required by the security constraint
guarding this request URI. Return true if this constraint was not
violated and processing should continue, of false if we have created a
response already.

B<Parameters:>

=over

=item $request

the B<Wombat::HttpRequest> being processed

=item $response

the B<Wombat::HttpResponse> being created

=item $constraint

the B<Wombat::Deploy::SecurityConstraint> being checked

=back

B<Throws:>

=over

=item B<Servlet::Util::IOException>

if an input or output error occurs

=back

=cut

sub checkUserData {
    my $self = shift;
    my $request = shift;
    my $response = shift;
    my $constraint = shift;

    return 1 unless $constraint;

    my $userConstraint = $constraint->getUserConstraint();
    return 1 unless $userConstraint;

    # no transport security required
    return 1 if $userConstraint eq TRANSPORT_NONE;

    my $freq = $request->getRequest();
    my $fres = $response->getResponse();

    # transport security is confirmed
    return 1 if $freq->isSecure();

    # XXX: support "redirect port" configuration on the connector that
    # allows us to redirect to an SSL port?

    $fres->sendError(Servlet::Http::HttpServletResponse::SC_FORBIDDEN,
                     $freq->getRequestURI());
    return undef;
}

=pod

=item findConstraint($request)

Return the B<Wombat::Deploy::SecurityConstraint> configured to guard
the request URI for this request, or C<undef> if there is no
constraint.

B<Parameters:>

=over

=item $request

the B<Wombat::HttpRequest> being processed

=back

=cut

sub findConstraint {
    my $self = shift;
    my $request = shift;

    my $freq = $request->getRequest();
    my $method = $freq->getMethod();
    my $uri = $freq->getRequestURI();

    my $contextPath = $freq->getContextPath();
    $uri =~ s|^$contextPath|| if $contextPath;
    $uri = URI::Escape::uri_unescape($uri);

    for my $constraint ($self->getContainer()->getConstraints()) {
        return $constraint if $constraint->included($uri, $method);
    }

    return undef;
}

=pod

=item getName()

Return a short name for this Authenticator implementation. Must be
overridden by subclasses.

=cut

sub getName {}

=pod

=item register($request, $response, $principal, $authType)

Register an authenticated Principal and authentication tyhpe in the
request and in the current session (if there is one).

B<Parameters:>

=over

=item $request

the B<Wombat::HttpRequest> being processed

=item $response

the B<Wombat::HttpResponse> being created

=item $principal

the authenticated B<Servlet::Util::Principal> to be registered

=item $uathType

the authentication type to be registered

=back

=cut

sub register {
    my $self = shift;
    my $request = shift;
    my $response = shift;
    my $principal = shift;
    my $authType = shift;

    $request->setAuthType($authType);
    $request->setUserPrincipal($principal);

    my $session = $self->getSession($request);
    if ($session) {
        $session->setAuthType($authType);
        $session->setPrincipal($principal);
    }

    return 1;
}

=pod

=back

=cut

# lifecycle methods.. no need to document

sub start {
    my $self = shift;

    $self->SUPER::start();
    $self->log(sprintf("%s started", $self->getName()), undef, 'INFO');

    return 1;
}

sub stop {
    my $self = shift;

    $self->SUPER::stop();
    $self->log(sprintf("%s stopped", $self->getName()), undef, 'DEBUG');

    return 1;
}

# private methods

sub getSession {
    my $self = shift;
    my $request = shift;

    my $freq = $request->getRequest();
    my $fses = $freq->getSession(1);
    return undef unless $fses;

    my $manager = $self->getContainer()->getSessionManager();
    return undef unless $manager;

    my $session;
    eval {
        $session = $manager->getSession($fses->getId());
    };

    return $session;
}

1;
__END__

=pod

=head1 SEE ALSO

L<Servlet::ServletException>,
L<Servlet::Util::Exception>,
L<Wombat::Core::Application>,
L<Wombat::Realm>,
L<Wombat::Valve::ValveBase>,
L<Wombat::ValveContext>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
