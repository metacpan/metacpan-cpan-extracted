# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::ServletRequestWrapper;

use base qw(Servlet::ServletRequest);
use fields qw(request);
use strict;
use warnings;

sub new {
    my $self = shift;
    my $request = shift;

    $self = fields::new($self) unless ref $self;

    $self->{request} = $request;

    return $self;
}

sub getAttribute {
    my $self = shift;

    return $self->getRequest()->getAttribute(@_);
}

sub getAttributeNames {
    my $self = shift;

    return $self->getRequest()->getAttributeNames(@_);
}

sub getCharacterEncoding {
    my $self = shift;

    return $self->getRequest()->getCharacterEncoding(@_);
}

sub getContentLength {
    my $self = shift;

    return $self->getRequest()->getContentLength(@_);
}

sub getContentType {
    my $self = shift;

    return $self->getRequest()->getContentType(@_);
}

sub getInputHandle {
    my $self = shift;

    return $self->getRequest()->getInputHandle(@_);
}

sub getLocale {
    my $self = shift;

    return $self->getRequest()->getLocale(@_);
}

sub getLocales {
    my $self = shift;

    return $self->getRequest()->getLocales(@_);
}

sub getParameter {
    my $self = shift;

    return $self->getRequest()->getParameter(@_);
}

sub getParameterMap {
    my $self = shift;

    return $self->getRequest()->getParameterMap(@_);
}

sub getParameterNames {
    my $self = shift;

    return $self->getRequest()->getParameterNames(@_);
}

sub getParameterValues {
    my $self = shift;

    return $self->getRequest()->getParameterValues(@_);
}

sub getProtocol {
    my $self = shift;

    return $self->getRequest()->getProtocol(@_);
}

sub getReader {
    my $self = shift;

    return $self->getRequest()->getReader(@_);
}

sub getRemoteAddr {
    my $self = shift;

    return $self->getRequest()->getRemoteAddr(@_);
}

sub getRemoteHost {
    my $self = shift;

    return $self->getRequest()->getRemoteHost(@_);
}

sub getRequest {
    my $self = shift;

    return $self->{request};
}

sub getRequestDispatcher {
    my $self = shift;

    return $self->getRequest()->getRequestDispatcher(@_);
}

sub getScheme {
    my $self = shift;

    return $self->getRequest()->getScheme(@_);
}

sub getServerName {
    my $self = shift;

    return $self->getRequest()->getServerName(@_);
}

sub getServerPort {
    my $self = shift;

    return $self->getRequest()->getServerPort(@_);
}

sub isSecure {
    my $self = shift;

    return $self->getRequest()->isSecure(@_);
}

sub removeAttribute {
    my $self = shift;

    return $self->getRequest()->removeAttribute(@_);
}

sub setAttribute {
    my $self = shift;

    return $self->getRequest()->setAttribute(@_);
}

sub setCharacterEncoding {
    my $self = shift;

    return $self->getRequest()->setCharacterEncoding(@_);
}

sub setRequest {
    my $self = shift;
    my $request = shift;

    $self->{request} = $request;

    return 1;
}

1;
__END__

=pod

=head1 NAME

Servlet::ServletRequestWrapper - servlet request wrapper class

=head1 SYNOPSIS

  my $wrapper = Servlet::ServletRequestWrapper->new($request);

  my $req = $wrapper->getRequest();
  $wrapper->setRequest($req);

=head1 DESCRIPTION

Provides a convenient implementation of the ServletRequest
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

the B<Servlet::ServletRequest> to be wrapped

=back

=back

=head1 METHODS

=over

=item getRequest()

Returns the wrapped B<Servlet::ServletRequest>

=item setRequest($request)

Specify a new request object to be wrapped.

B<Parameters:>

=over

=item I<$request>

the B<Servlet::ServletRequest> to be wrapped

=back

=back

=head1 SEE ALSO

L<Servlet::ServletRequest>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
