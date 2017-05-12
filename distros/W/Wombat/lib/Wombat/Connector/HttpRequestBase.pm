# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Connector::HttpRequestBase;

=pod

=head1 NAME

Wombat::Connector::HttpRequestBase - internal http request base class

=head1 SYNOPSIS

  package My::Connector::HttpRequest;

  use base qw(Wombat::Connector::HttpRequestBase);

=head1 DESCRIPTION

Convenience base implementation of B<Wombat::HttpRequest> and
B<Servlet::Http::HttpServletRequest> which can be used for most
connectors that implement the HTTP protocol. Only connector-specific
methods need to be implemented. Extends
B<Wombat::Connector::RequestBase>.

=cut

use base qw(Wombat::HttpRequest Wombat::Connector::RequestBase);
use fields qw(authType contextPath cookies headers method pathInfo parsed);
use fields qw(queryString requestedSessionCookie requestedSessionId);
use fields qw(requestedSessionURL requestURI servletPath session);
use fields qw(userPrincipal);
use strict;
use warnings;

use HTTP::Headers ();
use Wombat::Connector::HttpRequestFacade ();
use Wombat::Globals ();
use Wombat::Util::RequestUtil ();

=pod

=head1 CONSTRUCTOR

=over

=item new()

Construct and return a B<Wombat::Connector::Http::RequestBase>
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

=head1 PUBLIC METHODS

=over

=item getAuthType()

Return the authentication type used for this Request.

=cut

sub getAuthType {
    my $self = shift;

    return $self->{authType};
}

=pod

=item setAuthType($type)

Set the authentication type used for this request.

B<Parameters:>

=over

=item $type

the authentication type, as defined in
C<Servlet::Http::HttpServletRequest>

=back

=cut

sub setAuthType {
    my $self = shift;
    my $type = shift;

    $self->{authType} = $type;

    return 1;
}

=pod

=item getContextPath()

Return the portion of the request URI used to select the Application
for the Request.

=cut

sub getContextPath {
    my $self = shift;

    return $self->{contextPath};
}

=pod

=item setContextPath($path)

Set the context path for this Request. This will normally be called
when the associated Application is mapping the Request to a particular
Wrapper.

B<Parameters:>

=over

=item $path

the context path

=back

=cut

sub setContextPath {
    my $self = shift;
    my $path = shift;

    $self->{contextPath} = $path;
}

=pod

=item addCookie($cookie)

Add a Cookie to the set of Cookies for this Request. This will
normally be called when the Connector is parsing the request headers.

B<Parameters:>

=over

=item $cookie

the B<Servlet::Http::Cookie>

=back

=cut

sub addCookie {
    my $self = shift;
    my $cookie = shift;

    push @{ $self->{cookies} }, $cookie;

    return 1;
}

=pod

=item getCookies()

Return the set of Cookies received with this Request.

=cut

sub getCookies {
    my $self = shift;

    my @cookies = @{ $self->{cookies} };

    return wantarray ? @cookies : \@cookies;
}

=pod

=item clearCookies()

Remove all Cookies for this Request.

=cut

sub clearCookies {
    my $self = shift;

    $self->{cookies} = [];

    return 1;
}

=pod

=item getDateHeader($name)

Return the value of the named date header, or -1.

B<Parameters:>

=over

=item $name

the header name

=back

=cut

sub getDateHeader {
    my $self = shift;
    my $name = shift;

    my $val = -1;
    if ($name) {
        my $match = lc $name;
        if ($match eq 'date') {
            $val = $self->{headers}->date();
        } elsif ($match eq 'expires') {
            $val = $self->{headers}->expires();
        } elsif ($match eq 'if_modified_since') {
            $val = $self->{headers}->if_modified_since();
        } elsif ($match eq 'if_unmodified_since') {
            $val = $self->{headers}->if_unmodified_since();
        } elsif ($match eq 'last_modified') {
            $val = $self->{headers}->last_modified();
        }
    }

    return $val;
}

=pod

=item addHeader($name, $value)

Add a value for the named request header.

B<Parameters:>

=over

=item $name

the parameter name

=item $value

the parameter value, scalar

=back

=cut

sub addHeader
  {
    my $self = shift;
    my $name = shift;
    my $value = shift;

    $self->{headers}->push_header($name => $value);

    return 1;
  }

=pod

=item getHeader($name)

Return the first value for the named request header.

=cut

sub getHeader {
    my $self = shift;
    my $name = shift;

    return $self->getHeaders($name)->[0];
}

=pod

=item getHeaderNames()

Return the names of all headers received for this Request.

=cut

sub getHeaderNames {
    my $self = shift;

    my %names;
    $self->{headers}->scan(sub { $names{$_[0]} = 1 });

    my @names = keys %names;

    return wantarray ? @names : \@names;
}

=pod

=item getHeaders($name)

Return the list of values for the named request header.

B<Parameters:>

=over

=item $name

the header name

=back

=cut

sub getHeaders {
    my $self = shift;
    my $name = shift;

    my @vals = $self->{headers}->header($name);

    return wantarray ? @vals : \@vals;
}

=pod

=item clearHeaders()

Unset all headers for this Request.

=cut

sub clearHeaders {
    my $self = shift;

    $self->{headers}->scan(sub { $self->{headers}->remove_header($_[0]) });

    return 1;
}

=pod

=item getMethod()

Return the HTTP request method used for this Request.

=cut

sub getMethod {
    my $self = shift;

    return $self->{method};
}

=pod

=item setMethod($method)

Set the HTTP request method used for this Request.

B<Parameters:>

=over

=item $method

the request method

=back

=cut

sub setMethod {
    my $self = shift;
    my $method = shift;

    $self->{method} = $method;
}

=pod

=item getParameter($name)

Return the value of the named request parameter. If more than one
value is defined, return only the first one. Extract parameters from
the request if not already done.

B<Parameters:>

=over

=item $name

the name of the parameter

=back

=cut

sub getParameter {
    my $self = shift;
    my $name = shift;

    $self->parseParameters();

    my $param = $self->{parameters}->{$name};

    return defined $param ? $param->[0] : '';
}

=pod

=item getParameterMap()

Return a hash of the parameters of this Request. The keys of the hash
are the parameter names, and the values of the hash are arrays of
parameter values. Extract parameters from the request if not already
done.

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
this Request. Extract parameters from the request if not already done.

=cut

sub getParameterNames {
    my $self = shift;

    $self->parseParameters();

    my @names = keys %{ $self->{parameters} };

    return wantarray ? @names : \@names;
}

=pod

=item getParameterValues($name)

Return an array containing all of the values of the named request
parameter. Extract parameters from the request if not already done.

B<Parameters:>

=over

=item $name

the name of the parameter

=back

=cut

sub getParameterValues {
    my $self = shift;
    my $name = shift;

    $self->parseParameters();

    my @vals;
    my $param = $self->{parameters}->{$name};
    push @vals, @$param if defined $param;

    return wantarray ? @vals : \@vals;
}

sub parseParameters {
    my $self = shift;

    return 1 if $self->{parsed};

    my @uriwords =
        Wombat::Util::RequestUtil->parseParameters($self->getQueryString());
    for my $uriword (@uriwords) {
        $self->addParameter(@$uriword);
    }

    if ($self->getMethod() eq Servlet::Http::HttpServlet::METHOD_POST) {
        my $length = $self->getContentLength();
        my $type = $self->getContentType();
        $type = Wombat::Util::RequestUtil->parseContentType($type);

        if ($length && $type eq Wombat::Globals::FORM_TYPE_URLENCODED) {
            eval {
                my $handle = $self->getInputHandle();
                my $buf;
                my $read = $handle->read($buf, $length);

                my @uriwords =
                    Wombat::Util::RequestUtil->parseParameters($buf);
                for my $uriword (@uriwords) {
                    $self->addParameter(@$uriword);
                }
            };
            if ($@) {
                $self->log("problem parsing parameters", $@, 'ERROR');
            }
        }
    }

    $self->{parsed} = 1;

    return 1;
}

=pod

=item getPathInfo()

Return the path information for this Request.

=cut

sub getPathInfo {
    my $self = shift;

    return $self->{pathInfo};
}

=pod

=item setPathInfo($path)

Set the path information for this Request. This will normally be
called when the associated Application is mapping the Request to a
particular Wrapper.

B<Parameters:>

=over

=item $path

the path information

=back

=cut

sub setPathInfo {
    my $self = shift;
    my $path = shift;

    $self->{pathInfo} = $path;
}

=pod

=item getPathTranslated()

turn extra path information for this request, translated to a real
path.

=cut

sub getPathTranslated {
    my $self = shift;

    my $tr = undef;
    if ($self->{application} && defined $self->{pathInfo}) {
        my $context = $self->{application}->getServletContext();
        if ($context) {
            $tr = $context->getRealPath($self->{pathInfo});
        }
    }

    return $tr;
}

=pod

=item getQueryString()

Return the query string for this Request.

=cut

sub getQueryString {
    my $self = shift;

    return $self->{queryString};
}

=pod

=item setQueryString($query)

Set the query string for this Request. This is normally called by the
Connector when it parses the request headers.

B<Parameters:>

=over

=item $query

the query string

=back

=cut

sub setQueryString {
    my $self = shift;
    my $query = shift;

    $self->{queryString} = $query;
}

=pod

=item getRemoteUser()

Return the name of the remote user that has been authenticated for
this Request.

=cut

sub getRemoteUser {
    my $self = shift;

    return $self->{userPrincipal} ? $self->{userPrincipal}->getName() : undef;
}

=pod

=item isRequestedSessionIdFromCookie()

Return a flag indicating whether or not the requested session ID for
this Request came in through a cookie.

=cut

sub isRequestedSessionIdFromCookie {
    my $self = shift;

    return defined $self->{requestedSessionId} &&
        $self->{requestedSessionCookie};
}

=pod

=item setRequestedSessionCookie($flag)

Set a flag indicating whether or not the requested session ID for this
Request came in through a cookie. This is normally called by the
Connector when it parses the request headers.

B<Parameters:>

=over

=item $flag

a boolean value

=back

=cut

sub setRequestedSessionCookie {
    my $self = shift;
    my $flag = shift;

    $self->{requestedSessionCookie} = $flag;
}

=pod

=pod

=item getRequestedSessionId()

Return the session ID included in this Request, if any.

=cut

sub getRequestedSessionId {
    my $self = shift;

    return $self->{requestedSessionId};
}

=item setRequestedSessionId($id)

Set the requested session ID for this Request. This is normally called
by the Connector when it parses the request headers.

B<Parameters:>

=over

=item $id

the session id

=back

=cut

sub setRequestedSessionId {
    my $self = shift;
    my $id = shift;

    $self->{requestedSessionId} = $id;
}

=pod

=item isRequestedSessionIdFromURL()

Return a flag indicating whether or not the requested session ID for
this Request came in through the request URL.

=cut

sub isRequestedSessionIdFromURL {
    my $self = shift;

    return defined $self->{requestedSessionId} &&
        $self->{requestedSessionURL};
}

=pod

=item setRequestedSessionURL($flag)

Set a flag indicating whether or not the requested session ID for this
Request came in through the request URL. This is normally called by
the Connector when it parses the request headers.

B<Parameters:>

=over

=item $flag

a boolean value

=back

=cut

sub setRequestedSessionURL {
    my $self = shift;
    my $flag = shift;

    $self->{requestedSessionURL} = $flag;
}

=pod

=item getRequestURI()

Return the request URI for this Request.

=cut

sub getRequestURI {
    my $self = shift;

    return $self->{requestURI};
}

=pod

=item setRequestURI($uri)

Set the unparsed request URI for this Request. This is normally called
by the Connector when it parses the request headers.

B<Parameters:>

=over

=item $uri

the request URI

=back

=cut

sub setRequestURI {
    my $self = shift;
    my $uri = shift;

    $self->{requestURI} = $uri;
}

=pod

=item getRequestURL()

Reconstructs the URL the client used to make the request. The returned
URL contains a protocol, server name, port number, and server path,
but it does no tinclude query string parameters.

This method is useful for creating redirect messages and for reporting
errors.

=cut

sub getRequestURL {
    my $self = shift;

    my $scheme = $self->getScheme();

    my $authority = $self->getServerName();
    my $port = $self->getServerPort() || 80;
    $authority = join ':', $authority, $port unless $port == 80;

    my $url = sprintf("%s://%s%s", $self->getScheme, $authority,
                      $self->getRequestURI());

    return $url;
}

=pod

=item getServletPath()

Return the portion of the request URI used to select the servlet that
will process this Request.

=cut

sub getServletPath {
    my $self = shift;

    return $self->{servletPath};
}

=pod

=item setServletPath($path)

Set the servlet path for this Request. This is normally called when
the associated Application is mapping the Request to a particular
Wrapper.

B<Parameters:>

=over

=item $path

the servlet path

=back

=cut

sub setServletPath {
    my $self = shift;
    my $path = shift;

    $self->{servletPath} = $path;
}

=pod

=item getSession($boolean)

Return the Session associated with this Request, creating one if
necessary and requested.

B<Parameters:>

=over

=item $create

a flag indicating whether or not a session is to be created if one is
needed and does not exist

=back

=cut

sub getSession {
    my $self = shift;
    my $create = shift;

    # returns the session's facade, not the session itself

    return $self->{session}->getSession() if $self->{session};

    # can't have a session if no application has been assigned
    return undef unless $self->{application};
    return undef unless $self->{response};

    my $manager = $self->{application}->getSessionManager();

    # sessions are not supported
    return undef unless $manager;

    # get the requested session, if necessary
    if (defined $self->{requestedSessionId}) {
        eval {
            $self->{session} =
                $manager->getSession($self->{requestedSessionId});
        };
        if ($@) {
            my $msg = sprintf("problem getting session [id %s]",
                              $self->{requestedSessionId});
            $self->log($msg, $@, 'ERROR');
        }

        if ($self->{session}) {
#            Wombat::Globals::DEBUG &&
#                $self->log("got session " . $self->{session}->getId(),
#                           undef, 'DEBUG');
            return $self->{session}->getSession();
        }
    }

    # requested session didn't exist, was invalid, couldn't be gotten
    # for some other reason; or there was no requested session.

    return undef unless $create;

    # can't create a session if the response is already
    # committed. timing is important!
    return undef if $self->{application}->isSessionCookie() &&
        $self->{response}->isCommitted();

    eval {
        $self->{session} = $manager->createSession();
    };
    if ($@) {
        $self->log("problem creating session", $@, 'ERROR');
    }

    if ($self->{session}) {
#        Wombat::Globals::DEBUG &&
#            $self->log("created session " . $self->{session}->getId(),
#                       undef, 'DEBUG');
        return $self->{session}->getSession();
    }

    return undef;
}

=pod

=item setSession($session)

Set the internal Session associated with this Request.

B<Parameters:>

=over

=item $session

The B<Wombat::Core::Session> to set

=back

=cut

sub setSession {
    my $self = shift;
    my $session = shift;

    $self->{session} = $session;

    return 1;
}

=pod

=item getUserPrincipal()

Return the name of the current authenticated user.

=cut

sub getUserPrincipal {
    my $self = shift;

    return $self->{userPrincipal};
}

=pod

=item setUserPrincipal($principal)

Set the principal that has been authenticated for this Request. This
value is also used to calculate the value to be returned by
C<getRemoteUser()>.

B<Parameters:>

=over

=item $principal

the B<Servlet::Util::Principal> to set

=back

=cut

sub setUserPrincipal {
    my $self = shift;
    my $principal = shift;

    $self->{userPrincipal} = $principal;
}

=pod

=back

=head1 PUBLIC METHODS

=over

=item isRequestedSessionIdValid()

Return a boolean value indicating whether or not the requested session
ID is still valid.

=cut

sub isRequestedSessionIdValid {
    my $self = shift;

    return undef unless defined $self->{requestedSessionId};
    return undef unless $self->{context};

    my $manager = $self->{context}->getSessionManager;
    return undef unless $manager;

    my $session;
    eval {
        $session = $manager->getSession($self->{requestedSessionId});
    };
    if ($@) {
        my $msg = sprintf("problem getting session [id %s]",
                          $self->{requestedSessionId});
        $self->log($msg, $@, 'ERROR');
    }

    return $session && $session->isValid();
}

=pod

=item isUserInRole($role)

Return a boolean value indicating whether or not the authenticated
user principal is associated with the named role.

B<Parameters:>

=over

=item $role

the name of the role

=back

=cut

sub isUserInRole {
    my $self = shift;
    my $role = shift;

    return undef unless $self->{userPrincipal};
    return undef unless $self->{application};

    my $realm = $self->{application}->getRealm();
    return undef unless $realm;

    # first check for a role alias defined in a <security-role-ref>
    # element, then for a role defined directly as a <security-role>

    my @check = ($role);
    if ($self->{wrapper}) {
        my $realRole = $self->{wrapper}->getSecurityReference($role);
        unshift @check, $realRole if $realRole;
    }

    for my $check (@check) {
        return 1 if $realm->hasRole($self->{userPrincipal}, $check);
    }

    return undef;
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

    $self->{authType} = undef;
    $self->{contextPath} = '';
    $self->{cookies} = [];
    $self->{headers} = HTTP::Headers->new();
    $self->{method} = undef;
    $self->{parsed} = undef;
    $self->{pathInfo} = undef;
    $self->{queryString} = undef;
    $self->{requestedSessionCookie} = undef;
    $self->{requestedSessionId} = undef;
    $self->{requestedSessionURL} = undef;
    $self->{requestURI} = undef;
    $self->{servletPath} = undef;
    $self->{session} = undef;
    $self->{userPrincipal} = undef;

    $self->{facade} = $facade ||
        Wombat::Connector::HttpRequestFacade->new($self);

    return 1;
}

=pod

=back

=cut

1;
__END__

=pod

=head1 SEE ALSO

L<Servlet::Http::HttpServletRequest>,
L<Servlet::Util::Principal>,
L<Wombat::HttpRequest>,
L<Wombat::HttpSession>,
L<Wombat::Connector::RequestBase>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
