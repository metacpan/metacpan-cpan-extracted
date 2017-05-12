# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Connector::RequestFacade;

=pod

=head1 NAME

Wombat::Connector::RequestFacade - internal request facade

=head1 SYNOPSIS

=head1 DESCRIPTION

Facade class that wraps an internal Request object. All methods are
delegated to the wrapped request. The facade is presented to servlet
code so that the servlet code does not have access to internal Request
methods.

=cut

use base qw(Servlet::ServletRequest);
use fields qw(request);
use strict;
use warnings;

=pod

=head1 CONSTRUCTOR

=over

=item new($request)

Construct and return a B<Wombat::Connector::RequestFacade>
instance. If subclasses override the constructor, they must be sure to
call

  $self->SUPER::new($request);

B<Parameters:>

=over

=item $request

the B<Wombat::Request> for which this object is the facade.

=back

=back

=cut

sub new {
    my $self = shift;
    my $request = shift;

    $self = fields::new($self) unless ref $self;

    $self->{request} = $request;

    return $self;
}

sub getAttribute {
    my $self = shift;

    return $self->{request}->getAttribute(@_);
}

sub getAttributeNames {
    my $self = shift;

    return $self->{request}->getAttributeNames(@_);
}

sub removeAttribute {
    my $self = shift;

    return $self->{request}->removeAttribute(@_);
}

sub setAttribute {
    my $self = shift;

    return $self->{request}->setAttribute(@_);
}

sub getCharacterEncoding {
    my $self = shift;

    return $self->{request}->getCharacterEncoding(@_);
}

sub setCharacterEncoding {
    my $self = shift;

    return $self->{request}->setCharacterEncoding(@_);
}

sub getContentLength {
    my $self = shift;

    return $self->{request}->getContentLength(@_);
}

sub getContentType {
    my $self = shift;

    return $self->{request}->getContentType(@_);
}

sub getInputHandle {
    my $self = shift;

    return $self->{request}->getInputHandle(@_);
}

sub getLocale {
    my $self = shift;

    return $self->{request}->getLocale(@_);
}

sub getLocales {
    my $self = shift;

    return $self->{request}->getLocales(@_);
}

sub getParameter {
    my $self = shift;

    return $self->{request}->getParameter(@_);
}

sub getParameterMap {
    my $self = shift;

    return $self->{request}->getParameterMap(@_);
}

sub getParameterNames {
    my $self = shift;

    return $self->{request}->getParameterNames(@_);
}

sub getParameterValues {
    my $self = shift;

    return $self->{request}->getParameterValues(@_);
}

sub getProtocol {
    my $self = shift;

    return $self->{request}->getProtocol(@_);
}

sub getReader {
    my $self = shift;

    return $self->{request}->getReader(@_);
}

sub getRemoteAddr {
    my $self = shift;

    return $self->{request}->getRemoteAddr(@_);
}

sub getRemoteHost {
    my $self = shift;

    return $self->{request}->getRemoteHost(@_);
}

sub getRequestDispatcher {
    my $self = shift;

    return $self->{request}->getRequestDispatcher(@_);
}

sub getScheme {
    my $self = shift;

    return $self->{request}->getScheme(@_);
}

sub isSecure {
    my $self = shift;

    return $self->{request}->isSecure(@_);
}

sub getServerName {
    my $self = shift;

    return $self->{request}->getServerName(@_);
}

sub getServerPort {
    my $self = shift;

    return $self->{request}->getServerPort(@_);
}

1;
__END__

=pod

=head1 SEE ALSO

L<Servlet::ServletRequest>,
L<Wombat::Request>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
