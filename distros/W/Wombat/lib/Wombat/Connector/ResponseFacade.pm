# -*- Mode: Perl; indent-tabs-mode: nil; -*-

=pod

=head1 NAME

Wombat::Connector::ResponseFacade - internal response facade

=head1 SYNOPSIS

=head1 DESCRIPTION

Facade class that wraps an internal Response object. All methods are
delegated to the wrapped response. The facade is presented to servlet
code so that the servlet code does not have access to internal Response
methods.

=cut

package Wombat::Connector::ResponseFacade;

use base qw(Servlet::ServletResponse);
use fields qw(response);
use strict;
use warnings;

=head1 CONSTRUCTOR

=over

=item new($response)

Construct and return a B<Wombat::Connector::ResponseFacade>
instance. If subclasses override the constructor, they must be sure to
call

  $self->SUPER::new($response);

B<Parameters:>

=over

=item $response

the B<Wombat::Response> for which this object is the facade.

=back

=back

=cut

sub new {
    my $self = shift;
    my $response = shift;

    $self = fields::new($self) unless ref $self;

    $self->{response} = $response;

    return $self;
}

sub getBufferSize {
    my $self = shift;

    return $self->{response}->getBufferSize(@_);
}

sub getCharacterEncoding {
    my $self = shift;

    return $self->{response}->getCharacterEncoding(@_);
}

sub isCommitted {
    my $self = shift;

    return $self->{response}->isCommitted(@_);
}

sub setContentLength {
    my $self = shift;

    return $self->{response}->setContentLength(@_);
  }

sub setContentType {
    my $self = shift;

    return $self->{response}->setContentType(@_);
  }

sub getLocale {
    my $self = shift;

    return $self->{response}->getLocale(@_);
}

sub setLocale {
    my $self = shift;

    return $self->{response}->setLocale(@_);
  }

sub getOutputHandle {
    my $self = shift;

    return $self->{response}->getOutputHandle(@_);
}

sub getWriter {
    my $self = shift;

    return $self->{response}->getWriter(@_);
}

sub flushBuffer {
    my $self = shift;

    return $self->{response}->flushBuffer(@_);
}

sub reset {
    my $self = shift;

    return $self->{response}->reset(@_);
}

sub resetBuffer {
    my $self = shift;

    return $self->{response}->resetBuffer(@_);
}

1;
__END__

=pod

=head1 SEE ALSO

L<Servlet::ServletResponse>,
L<Wombat::Response>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
