# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Valve::ValveBase;

=pod

=head1 NAME

Wombat::Valve::ValveBase - valve base class

=head1 SYNOPSIS

=head1 DESCRIPTION

Convenience base implementation of B<Wombat::Valve>. Subclasses
B<MUST> implement C<invoke()> to provide the required functionality as
well as C<getName()>.

=cut

use base qw(Wombat::Valve);
use fields qw(container started);
use strict;
use warnings;

=pod

=head1 CONSTRUCTOR

=over

=item new()

Construct and return a B<Wombat::Valve::ValveBase> instance,
initializing fields appropriately. If subclasses override the
constructor, they must be sure to call

  $self->SUPER::new();

=back

=cut

sub new {
    my $self = shift;

    $self = fields::new($self) unless ref $self;

    $self->{container} = undef;
    $self->{started} = undef;

    return $self;
}

=pod

=head1 ACCESSOR METHODS

=over

=item getContainer()

Return the Container to which this Valve is attached.

=cut

sub getContainer {
    my $self = shift;

    return $self->{container};
}

=pod

=item setContainer($container)

Set the Container to which this Valve is attached.

B<Parameters:>

=over

=item $container

the B<Wombat::Container> to which this Valve is attached.

=back

=cut

sub setContainer {
    my $self = shift;
    my $container = shift;

    $self->{container} = $container;

    return 1;
}

=pod

=back

=head1 PUBLIC METHODS

=over

=item invoke ($request, $response, $context)

Perform request processing as required by this Valve.

B<Parameters>

=over

=item $request

the B<Wombat::Request> to be processed

=item $response

the B<Wombat::Response> to be created

=item $context

the B<Wombat::ValveContext> allowing access to the next Valve in the
Pipeline being processed

=back

B<Throws:>

=over

=item B<Servlet::ServletException>

if a servlet error occurs or is thrown by a subsequently invoked
Valve, Filter or Servlet

=item B<Servlet::Util::IOException>

if an input or output error occurs

=back

=cut

sub invoke {}

=pod

=back

=head1 PACKAGE METHODS

=over

=item getName()

Return a short name for this Valve implementation. Must be overridden
by subclasses.

=cut

sub getName {}

=pod

=back

=head1 LIFECYCLE METHODS

=over

=item start()

Prepare for active use of this component. This method should be called
before any of the public methods of the component are utilized.

B<Throws:>

=over

=item B<Wombat::LifecycleException>

if the component has already been started

=back

=cut

sub start {
    my $self = shift;

    if ($self->{started}) {
        my $msg = "start: valve already started";
        Wombat::LifecycleException->throw($msg);
    }

    $self->{started} = 1;

    return 1;
}

=pod

=item stop()

Gracefully terminate active use of this component. Once this method
has been called, no public methods of the component should be
utilized.

B<Throws:>

=over

=item B<Wombat::LifecycleException>

if the component is not started

=back

=cut

sub stop {
    my $self = shift;

    unless ($self->{started}) {
        my $msg = "stop: valve not started";
        Wombat::LifecycleException->throw($msg);
    }

    undef $self->{started};

    return 1;
}

=pod

=back

=cut

# private methods

sub log {
    my $self = shift;

    $self->{container}->log(@_) if $self->{container};

    return 1;
}

1;
__END__

=pod

=head1 SEE ALSO

L<Servlet::ServletException>,
L<Servlet::Util::Exception>,
L<Wombat::Container>,
L<Wombat::Exception>,
L<Wombat::Valve>,
L<Wombat::ValveContext>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
