# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Core::MapperBase;

=pod

=head1 NAME

Wombat::Core::MapperBase - internal mapper base class

=head1 SYNOPSIS

=head1 DESCRIPTION

Convenience base implementation of B<Wombat::Mapper>. Classes
extending this base class must implement C<map()>.

=cut

use base qw(Wombat::Mapper);
use fields qw(container protocol);
use strict;
use warnings;

=pod

=head1 CONSTRUCTOR

=over

=item new()

Construct and return a B<Wombat::Core::MapperBase> instance,
initializing fields appropriately. If subclasses override the
constructor, they must be sure to call

  $self->SUPER::new();

=back

=cut

sub new {
    my $self = shift;

    $self = fields::new($self) unless ref $self;

    $self->{container} = undef;
    $self->{protocol} = undef;

    return $self;
}

=pod

=head1 ACCESSOR METHODS

=over

=item getContainer()

Return the Container with which the Mapper is associated.

=cut

sub getContainer {
    my $self = shift;

    return $self->{container};
}

=pod

=item setContainer($container)

Set the Container with which the Mapper is associated.

B<Parameters:>

=over

=item $container

the B<Wombat::Container> used for processing Requests

=back

B<Throws:>

=over

=item B<Servlet::Util::IllegalArgumentException>

if the Container is not acceptable to this Mapper

=back

=cut

sub setContainer {
    my $self = shift;
    my $container = shift;

    $self->{container} = $container;

    return 1;
}

=pod

=item getProtocol()

Return the protocol for which this Mapper is responsible.

=cut

sub getProtocol {
    my $self = shift;

    return $self->{protocol};
}

=pod

=item setProtocol($protocol)

Set the protocol for which this Mapper is responsible.

B<Parameters:>

=over

=item $protocol

the protocol

=back

=cut

sub setProtocol {
    my $self = shift;
    my $protocol = shift;

    $self->{protocol} = $protocol;

    return 1;
}

=pod

=back

=head1 PUBLIC METHODS

=over

=item map($request)

Return the child Container that should be used to process the
Request, or C<undef> f no such child Container can be identified.

B<Parameters:>

=over

=item $request

the B<Wombat::Request> being processed

=back

=cut

sub map {}

1;
__END__

=back

=head1 SEE ALSO

L<Servlet::Util::Exception>,
L<Wombat::Container>,
L<Wombat::Mapper>,
L<Wombat::Request>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
