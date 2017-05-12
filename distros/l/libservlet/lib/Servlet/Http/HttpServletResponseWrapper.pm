# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::Http::HttpServletResponseWrapper;

use base qw(Servlet::ServletResponseWrapper);
use strict;
use warnings;

sub addCookie {
    my $self = shift;

    return $self->getResponse()->addCookie(@_);
}

sub addDateHeader {
    my $self = shift;

    return $self->getResponse()->addDateHeader(@_);
}

sub addHeader {
    my $self = shift;

    return $self->getResponse()->addHeader(@_);
}

sub containsHeader {
    my $self = shift;

    return $self->getResponse()->containsHeader(@_);
}

sub encodeRedirectURL {
    my $self = shift;

    return $self->getResponse()->encodeRedirectURL(@_);
}

sub encodeURL {
    my $self = shift;

    return $self->getResponse()->encodeURL(@_);
}

sub sendError {
    my $self = shift;

    return $self->getResponse()->sendError(@_);
}

sub sendRedirect {
    my $self = shift;

    return $self->getResponse()->sendRedirect(@_);
}

sub setDateHeader {
    my $self = shift;

    return $self->getResponse()->setDateHeader(@_);
}

sub setHeader {
    my $self = shift;

    return $self->getResponse()->setHeader(@_);
}

sub setStatus {
    my $self = shift;

    return $self->getResponse()->setStatus(@_);
}

1;
__END__

=pod

=head1 NAME

Servlet::Http::HttpServletResponseWrapper - HTTP servlet response wrapper class

=head1 SYNOPSIS

  my $wrapper = Servlet::Http::HttpServletResponseWrapper->new($response);

  my $reqs= $wrapper->getResponse();
  $wrapper->setResponse($res);

=head1 DESCRIPTION

Provides a convenient implementation of the HttpServletResponse
interface that may be subclassed by developers wishing to adapt the
response to a Servlet. This class implements the Wrapper or Decorator
pattern. Methods default to calling through to the wrapped response object.

=head1 CONSTRUCTOR

=over

=item new($response)

Construct an instance with the given response object

B<Parameters:>

=over

=item I<$response>

the B<Servlet::Http::HttpServletResponse> to be wrapped

=back

=back

=head1 METHODS

=over

=item getResponse()

Returns the wrapped B<Servlet::Http::HttpServletResponse>

=item setResponse($response)

Specify a new response object to be wrapped.

B<Parameters:>

=over

=item I<$response>

the B<Servlet::Http::HttpServletResponse> to be wrapped

=back

=back

=head1 SEE ALSO

L<Servlet::Http::HttpServletResponse>,
L<Servlet::ServletResponseWrapper>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
