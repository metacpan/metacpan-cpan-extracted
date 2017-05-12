# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Core::WrapperFacade;

=pod

=head1 NAME

Wombat::Core::WrapperFacade - internal wrapper facade

=head1 SYNOPSIS

=head1 DESCRIPTION

Facade class that wraps an internal Wrapper object. All methods are
delegated to the wrapped wrapper. The facade is presented to servlet
code so that the servlet code does not have access to internal Wrapper
methods.

=cut

use base qw(Servlet::ServletConfig);
use fields qw(wrapper);
use strict;
use warnings;

=pod

=head1 CONSTRUCTOR

=over

=item new($wrapper)

Construct and return a B<Wombat::Connector::WrapperFacade>
instance. If subclasses override the constructor, they must be sure to
call

  $self->SUPER::new($wrapper);

B<Parameters:>

=over

=item $wrapper

the B<Wombat::Core::Wrapper> for which this object is the facade.

=back

=back

=cut

sub new {
    my $self = shift;
    my $wrapper = shift;

    $self = fields::new($self) unless ref $self;

    $self->{wrapper} = $wrapper;

    return $self;
}

sub getInitParameter {
    my $self = shift;

    return $self->{wrapper}->getInitParameter(@_);
}

sub getInitParameterNames {
    my $self = shift;

    return $self->{wrapper}->getInitParameterNames(@_);
}

sub getServletContext {
    my $self = shift;

    return $self->{wrapper}->getServletContext(@_);
}

sub getServletName {
    my $self = shift;

    return $self->{wrapper}->getServletName(@_);
}

1;
__END__

=pod

=head1 SEE ALSO

L<Servlet::ServletConfig>,
L<Wombat::Core::Wrapper>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
