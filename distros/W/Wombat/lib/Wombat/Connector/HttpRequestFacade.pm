# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Connector::HttpRequestFacade;

=pod

=head1 NAME

Wombat::Connector::HttpRequestFacade - internal http request facade

=head1 SYNOPSIS

=head1 DESCRIPTION

Facade class that wraps an internal HttpRequest object. All methods are
delegated to the wrapped request. The facade is presented to servlet
code so that the servlet code does not have access to internal HttpRequest
methods.

=cut

use base qw(Servlet::Http::HttpServletRequest Wombat::Connector::RequestFacade);
use strict;
use warnings;

sub getAuthType {
    my $self = shift;

    return $self->{request}->getAuthType(@_);
}

sub getContextPath {
    my $self = shift;

    return $self->{request}->getContextPath(@_);
}

sub getCookies {
    my $self = shift;

    return $self->{request}->getCookies(@_);
}

sub getDateHeader {
    my $self = shift;

    return $self->{request}->getDateHeader(@_);
}

sub getHeader {
    my $self = shift;

    return $self->{request}->getHeader(@_);
}

sub getHeaderNames {
    my $self = shift;

    return $self->{request}->getHeaderNames(@_);
}

sub getHeaders {
    my $self = shift;

    return $self->{request}->getHeaders(@_);
}

sub getIntHeader {
    my $self = shift;

    return $self->{request}->getIntHeader(@_);
}

sub getMethod {
    my $self = shift;

    return $self->{request}->getMethod(@_);
}

sub getPathInfo {
    my $self = shift;

    return $self->{request}->getPathInfo(@_);
}

sub getPathTranslated {
    my $self = shift;

    return $self->{request}->getPathTranslated(@_);
}

sub getQueryString {
    my $self = shift;

    return $self->{request}->getQueryString(@_);
}

sub getRemoteUser {
    my $self = shift;

    return $self->{request}->getRemoteUser(@_);
}

sub getRequestedSessionId {
    my $self = shift;

    return $self->{request}->getRequestedSessionId(@_);
}

sub getRequestURI {
    my $self = shift;

    return $self->{request}->getRequestURI(@_);
}

sub getRequestURL {
    my $self = shift;

    return $self->{request}->getRequestURL(@_);
}

sub getServletPath {
    my $self = shift;

    return $self->{request}->getServletPath(@_);
}

sub getSession {
    my $self = shift;

    return $self->{request}->getSession(@_);
}

sub getUserPrincipal {
    my $self = shift;

    return $self->{request}->getUserPrincipal(@_);
}

sub isRequestedSessionIdFromCookie {
    my $self = shift;

    return $self->{request}->isRequestedSessionIdFromCookie(@_);
}

sub isRequestedSessionIdFromURL {
    my $self = shift;

    return $self->{request}->isRequestedSessionIdFromURL(@_);
}

sub isRequestedSessionIdValid {
    my $self = shift;

    return $self->{request}->isRequestedSessionIdValid(@_);
}

sub isUserInRole {
    my $self = shift;

    return $self->{request}->isUserInRole(@_);
}

1;
__END__

=pod

=head1 SEE ALSO

L<Servlet::Http::HttpServletRequest>,
L<Wombat::Connector::RequestFacade>,
L<Wombat::HttpRequest>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
