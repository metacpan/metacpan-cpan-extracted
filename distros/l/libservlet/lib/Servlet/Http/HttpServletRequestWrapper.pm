# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::Http::HttpServletRequestWrapper;

use base qw(Servlet::ServletRequestWrapper);
use strict;
use warnings;

sub getAuthType {
    my $self = shift;

    return $self->getRequest()->getAuthType(@_);
}

sub getContextPath {
    my $self = shift;

    return $self->getRequest()->getContextPath(@_);
}

sub getCookies {
    my $self = shift;

    return $self->getRequest()->getCookies(@_);
}

sub getDateHeader {
    my $self = shift;

    return $self->getRequest()->getDateHeader(@_);
}

sub getHeader {
    my $self = shift;

    return $self->getRequest()->getHeader(@_);
}

sub getHeaderNames {
    my $self = shift;

    return $self->getRequest()->getHeaderNames(@_);
}

sub getHeaders {
    my $self = shift;

    return $self->getRequest()->getHeaders(@_);
}

sub getIntHeader {
    my $self = shift;

    return $self->getRequest()->getIntHeader(@_);
}

sub getMethod {
    my $self = shift;

    return $self->getRequest()->getMethod(@_);
}

sub getPathInfo {
    my $self = shift;

    return $self->getRequest()->getPathInfo(@_);
}

sub getPathTranslated {
    my $self = shift;

    return $self->getRequest()->getPathTranslated(@_);
}

sub getQueryString {
    my $self = shift;

    return $self->getRequest()->getQueryString(@_);
}

sub getRemoteUser {
    my $self = shift;

    return $self->getRequest()->getRemoteUser(@_);
}

sub getRequestedSessionId {
    my $self = shift;

    return $self->getRequest()->getRequestedSessionId(@_);
}

sub getRequestURI {
    my $self = shift;

    return $self->getRequest()->getRequestURI(@_);
}

sub getRequestURL {
    my $self = shift;

    return $self->getRequest()->getRequestURL(@_);
}

sub getServletPath {
    my $self = shift;

    return $self->getRequest()->getServletPath(@_);
}

sub getSession {
    my $self = shift;

    return $self->getRequest()->getSession(@_);
}

sub getUserPrincipal {
    my $self = shift;

    return $self->getRequest()->getUserPrincipal(@_);
}

sub isRequestedSessionIdFromCookie {
    my $self = shift;

    return $self->getRequest()->isRequestedSessionIdFromCookie(@_);
}

sub isRequestedSessionIdFromURL {
    my $self = shift;

    return $self->getRequest()->isRequestedSessionIdFromURL(@_);
}

sub isRequestedSessionIdValid {
    my $self = shift;

    return $self->getRequest()->isRequestedSessionIdValid(@_);
}

sub isUserInRole {
    my $self = shift;

    return $self->getRequest()->isUserInRole(@_);
}

1;
__END__

=pod

=head1 NAME

Servlet::Http::HttpServletRequestWrapper - HTTP servlet request wrapper class

=head1 SYNOPSIS

  my $wrapper = Servlet::Http::HttpServletRequestWrapper->new($request);

  my $req = $wrapper->getRequest();
  $wrapper->setRequest($req);

=head1 DESCRIPTION

Provides a convenient implementation of the HttpServletRequest
interface that may be subclassed by developers wishing to adapt the
request to a Servlet. This class implements the Wrapper or Decorator
pattern. Methods default to calling through to the wrapped request object.

=head1 CONSTRUCTOR

=over

=item new($request)

Construct an instance with the given request object

B<Parameters:>

=over

=item I<$request>

the B<Servlet::Http::HttpServletRequest> to be wrapped

=back

=back

=head1 METHODS

=over

=item getRequest()

Returns the wrapped B<Servlet::Http::HttpServletRequest>

=item setRequest($request)

Specify a new request object to be wrapped.

B<Parameters:>

=over

=item I<$request>

the B<Servlet::Http::HttpServletRequest> to be wrapped

=back

=back

=head1 SEE ALSO

L<Servlet::Http::HttpServletRequest>,
L<Servlet::ServletRequestWrapper>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
