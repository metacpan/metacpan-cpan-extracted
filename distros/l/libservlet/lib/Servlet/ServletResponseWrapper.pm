# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::ServletResponseWrapper;

use base qw(Servlet::ServletResponse);
use fields qw(response);
use strict;
use warnings;

sub new {
    my $self = shift;
    my $response = shift;

    $self = fields::new($self) unless ref $self;

    $self->{response} = $response;

    return $self;
}

sub flushBuffer {
    my $self = shift;

    $self->getResponse()->flushBuffer();
}

sub getBufferSize {
    my $self = shift;

    $self->getResponse()->getBufferSize();
}

sub getCharacterEncoding {
    my $self = shift;

    $self->getResponse()->getCharacterEncoding();
}

sub getLocale {
    my $self = shift;

    $self->getResponse()->getLocale();
}

sub getOutputHandle {
    my $self = shift;

    $self->getResponse()->getOutputHandle();
}

sub getWriter {
    my $self = shift;

    $self->getResponse()->getWriter();
}

sub getResponse {
    my $self = shift;

    return $self->{response};
}

sub isCommitted {
    my $self = shift;

    $self->getResponse()->isCommitted();
}

sub reset {
    my $self = shift;

    $self->getResponse()->reset();
}

sub resetBuffer {
    my $self = shift;

    $self->getResponse()->resetBuffer();
}

sub setBufferSize {
    my $self = shift;
    my $size = shift;

    $self->getResponse()->setBufferSize($size);
}

sub setContentLength {
    my $self = shift;
    my $len = shift;

    $self->getResponse()->setContentLength($len);
}

sub setContentType {
    my $self = shift;
    my $type = shift;

    $self->getResponse()->setContentType($type);
}

sub setLocale {
    my $self = shift;
    my $loc = shift;

    $self->getResponse()->setLocale($loc);
}

sub setResponse {
    my $self = shift;
    my $response = shift;

    $self->{response} = $response;

    return 1;
}

1;
__END__

=pod

=head1 NAME

Servlet::ServletResponseWrapper - servlet response wrapper class

=head1 SYNOPSIS

  my $wrapper = Servlet::ServletResponseWrapper->new($response);

  my $res = $wrapper->getResponse();
  $wrapper->setResponse($res);

=head1 DESCRIPTION

Provides a convenient implementation of the ServletResponse
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

the B<Servlet::ServletResponse> to be wrapped

=back

=back

=head1 METHODS

=over

=item getResponse()

Returns the wrapped B<Servlet::ServletResponse>

=item setResponse($response)

Specify a new response object to be wrapped.

B<Parameters:>

=over

=item I<$response>

the B<Servlet::ServletResponse> to be wrapped

=back

=back

=head1 SEE ALSO

L<Servlet::ServletResponse>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
