# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Core::SessionFacade;

=pod

=head1 NAME

Wombat::Core::SessionFacade - internal session facade

=head1 SYNOPSIS

=head1 DESCRIPTION

Facade class that wraps an internal Session object. All methods are
delegated to the wrapped sessoin. The facade is presented to servlet
code so that the servlet code does not have access to internal Session
methods.

=cut

use base qw(Servlet::Http::HttpSession);
use fields qw(session);
use strict;
use warnings;

=pod

=head1 CONSTRUCTOR

=over

=item new()

Construct and return a B<Wombat::Core::SessionFacade> instance,
initializing fields appropriately.

B<Parameters:>

=over

=item $session

the B<Wombat::Core::Session> for which this object is the facade.

=back

=back

=cut

sub new {
    my $self = shift;
    my $session = shift;

    $self = fields::new($self) unless ref $self;

    $self->{session} = $session;

    return $self;
}

sub getAttribute {
    my $self = shift;

    return $self->{session}->getAttribute(@_);
}

sub getAttributeNames {
    my $self = shift;

    return $self->{session}->getAttributeNames(@_);
}

sub removeAttribute {
    my $self = shift;

    return $self->{session}->removeAttribute(@_);
}

sub setAttribute {
    my $self = shift;

    return $self->{session}->setAttribute(@_);
}

sub getCreationTime {
    my $self = shift;

    return $self->{session}->getCreationTime(@_);
}

sub getId {
    my $self = shift;

    return $self->{session}->getId(@_);
}

sub getLastAccessedTime {
    my $self = shift;

    return $self->{session}->getLastAccessedTime(@_);
}

sub getMaxInactiveInterval {
    my $self = shift;

    return $self->{session}->getMaxInactiveInterval(@_);
}

sub setMaxInactiveInterval {
    my $self = shift;

    return $self->{session}->setMaxInactiveInterval(@_);
}

sub isNew {
    my $self = shift;

    return $self->{session}->isNew(@_);
}

sub invalidate {
    my $self = shift;

    return $self->{session}->invalidate(@_);
}

1;
__END__

=pod

=head1 SEE ALSO

L<Servlet::Http::HttpSession>,
L<Wombat::Core::Session>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
