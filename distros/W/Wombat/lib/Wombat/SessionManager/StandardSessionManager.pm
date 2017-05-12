# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::SessionManager::StandardSessionManager;

=pod

=head1 NAME

Wombat::SessionManager::StandardSessionManager - caching session
manager implementation

=head1 SYNOPSIS

=head1 DESCRIPTION

Subclass of B<Wombat::SessionManager::SessionManagerBase> that uses an
implementation of B<Cache::Cache> to manage a lightweight cache of
sessions. Typically B<Cache::MemoryCache> will be used in
single-process scenarios; B<Cache::SharedMemoryCache> is useful for
multi-process deployments. This class does not support any persistence
or distributable capabilities.

=cut

use base qw(Wombat::SessionManager::SessionManagerBase);
use fields qw(cache cacheClass);
use strict;
use warnings;

use Wombat::Exception ();

=pod

=head1 CONSTRUCTOR

=over

=item new()

Construct and return a B<Wombat::SessionManager::StandardSessionManager>
instance, initializing fields appropriately. If subclasses override
the constructor, they must be sure to call

  $self->SUPER::new();

=back

=cut

sub new {
    my $self = shift;

    $self = fields::new($self) unless ref $self;
    $self->SUPER::new();

    $self->{cacheClass} = {};
    $self->{cache} = undef;

    return $self;
}

=pod

=head1 ACCESSOR METHODS

=over

=item getCacheClass()

Return the cache class for this SessionManager.

=cut

sub getCacheClass {
    my $self = shift;

    return $self->{cacheClass};
}

=pod

=item setCacheClass($class)

Set the cache class for this SessionManager.

B<Parameters:>

=over

=item $class

the B<Cache::Cache> implementation to use for the cache

=back

=cut

sub setCacheClass {
    my $self = shift;
    my $class = shift;

    $self->{cacheClass} = $class;

    return 1;
}

=back

=head1 PUBLIC METHODS

=over

=back

=head1 PACKAGE METHODS

=over

=item add($session)

Add this Session to the cache of active Sessions for this
SessionManager.

B<Parameters:>

=over

=item $session

the B<Wombat::Session> to be added

=back

=cut

sub add {
    my $self = shift;
    my $session = shift;

    # don't use Cache::Cache's expiration mechanism since we have our
    # own expiration model. this means that if a Session is not found
    # in the cache, it never existed or has previously been explicitly
    # removed.

    $self->{cache}->set($session->getId(), $session);

    return 1;
}

=pod

=item getName()

Return the display name of this SessionManager.

=cut

sub getName {
    return "StandardSessionManager";
}

=pod

=item getSession($id)

Return the active Session cached by this SessionManager with the
specified id, or C<undef> if no session exists with that id.

B<Parameters:>

=over

=item $id

the id for the Session to be returned

=back

=cut

sub getSession {
    my $self = shift;
    my $id = shift;

    return $self->{cache}->get($id);
}

=pod

=item getSessions()

Return an array containing the active Sessions cached by this
SessionManager.

=cut

sub getSessions {
    my $self = shift;

    warn "ids: ", join('|', $self->{cache}->get_identifiers()), "\n";

    my @sessions = map { $self->{cache}->get($_) }
        $self->{cache}->get_identifiers();

    return wantarray ? @sessions : \@sessions;
}

=pod

=item remove($session)

Remove this Session from this SessionManager's cache.

B<Parameters:>

=over

=item $session

the B<Wombat::Session> to remove

=back

=cut

sub remove {
    my $self = shift;
    my $session = shift;

    $self->{cache}->remove($session->getId()) if $session;

    return 1;
}

=pod

=item save($session)

Write the current state of this Session to this SessionManager's
cache.

B<Parameters:>

=over

=item $session

the B<Wombat::Session> to save

=back

=cut

sub save {
    my $self = shift;
    my $session = shift;

    $self->{cache}->set($session->getId(), $session);

    return 1;
}

=pod

=back

=head1 LIFECYCLE METHODS

=over

=item start()

Prepare for active use of this SessionManager and initialize the
session cache. This method should be called before any of the public
methods of the SessionManager are utilized.

B<Throws:>

=over

=item B<Wombat::LifecycleException>

if the SessionManager has already been started or if the cache cannot
be initialized

=back

=cut

sub start {
    my $self = shift;

    $self->SUPER::start();

    undef $self->{started};

    my $class = $self->{cacheClass};

    # load cache class
    eval "require $class";
    if ($@) {
        my $msg = "setCacheClass: class load problem: $@";
        Wombat::LifecycleException->throw($msg);
    }

    # ensure the cache class implements Cache::Cache
    unless (UNIVERSAL::isa($class, 'Cache::Cache')) {
        my $msg = "setCacheClass: class [$class] does not extend Cache::Cache";
        Wombat::LifecycleException->throw($msg);
    }

    $self->{cache} = $class->new({namespace => 'Wombat'});

    $self->{started} = 1;

    return 1;
}

1;
__END__

=pod

=back

=head1 SEE ALSO

L<Cache::Cache>,
L<Wombat::Container>,
L<Wombat::Core::Session>,
L<Wombat::SessionManager::SessionManagerBase>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
