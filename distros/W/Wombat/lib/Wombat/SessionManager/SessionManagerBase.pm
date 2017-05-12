# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::SessionManager::SessionManagerBase;

=pod

=head1 NAME

Wombat::SessionManager::SessionManagerBase - session manager base class

=head1 SYNOPSIS

=head1 DESCRIPTION

Minimal base implementation of B<Wombat::SessionManager>. This class
supports no session persistence or distributable capabilities. This
class may be subclassed to create more sophisticated Manager
implementations.  Subclasses B<MUST> override C<add()>, C<getName()>,
C<getSession()>, C<getSessions()>, and C<remove()>.

=cut

use base qw(Wombat::SessionManager);
use fields qw(container digest maxInactiveInterval started);
use strict;
use warnings;

use Digest::MD5 ();
use Wombat::Core::Session ();
use Wombat::Exception ();
use Wombat::Globals ();

use constant DEFAULT_MAX_INACTIVE_INTERVAL => 60;

=pod

=head1 CONSTRUCTOR

=over

=item new()

Construct and return a B<Wombat::SessionManager::SessionManagerBase>
instance, initializing fields appropriately. If subclasses override
the constructor, they must be sure to call

  $self->SUPER::new();

=back

=cut

sub new {
    my $self = shift;

    $self = fields::new($self) unless ref $self;

    $self->{container} = undef;
    $self->{digest} = Digest::MD5->new();
    $self->{maxInactiveInterval} = DEFAULT_MAX_INACTIVE_INTERVAL;
    $self->{started} = undef;

    return $self;
}

=pod

=head1 ACCESSOR METHODS

=over

=item getContainer()

Return the Container for which this SessionManager manages Sessions.

=cut

sub getContainer {
    my $self = shift;

    return $self->{container};
}

=pod

=item setContainer($container)

Set the Container for which this SessionManager manages Sessions.

B<Parameters:>

=over

=item $container

the B<Wombat::Container>

=back

=cut

sub setContainer {
    my $self = shift;
    my $container = shift;

    $self->{container} = $container;

    return 1;
}

=pod

=item getMaxInactiveInterval()

Return the default maximum inactive interval in seconds for Sessions
created by this SessionManager.

=cut

sub getMaxInactiveInterval {
    my $self = shift;

    return $self->{maxInactiveInterval};
}

=pod

=item setMaxInactiveInterval($interval)

Set the default maximum inactive interval for Sessions created by this
SessionManager.

B<Parameters:>

=over

=item $interval

the new interval, in seconds

=back

=cut

sub setMaxInactiveInterval {
    my $self = shift;
    my $interval = shift;

    $self->{maxInactiveInterval} = $interval;

    return 1;
}

=pod

=back

=head1 PUBLIC METHODS

=over

=item createSession()

Construct and return a B<Wombat::Session>, based on the default
settings specified by this SessionManager's fields. The session id
will be assigned by this method.

B<Throws:>

=over

=item B<Servlet::Util::IllegalStateException>

if a new Session cannot be created for, any reason

=back

=cut

sub createSession {
    my $self = shift;

    my $session = Wombat::Core::Session->new();
    $session->setSessionManager($self);
    $session->setNew(1);
    $session->setValid(1);
    $session->setCreationTime(time);
    $session->setMaxInactiveInterval($self->getMaxInactiveInterval());

    my $id;
    while (1) {
        $id = $self->generateSessionId();
        # make sure the id is not already used by a currently active
        # session
        last unless $self->getSession($id);
    }
    $session->setId($id);

    return $session;
}

=pod

=back

=head1 PACKAGE METHODS

Subclasses B<MUST> override all of these methods.

=over

=item add($session)

Add this Session to the set of active Sessions for this
SessionManager.

B<Parameters:>

=over

=item $session

the B<Wombat::Session> to be added

=back

=cut

sub add {}

=pod

=item getName()

Return the display name of this SessionManager.

=cut

sub getName {}

=pod

=item getSession($id)

Return the active Session managed by this SessionManager with the
specified id, or C<undef> if no session exists with that id.

B<Parameters:>

=over

=item $id

the id for the Session to be returned

=back

B<Throws:>

=over

=item B<Servlet::Util::IllegalStateException>

if the session exists but cannot be returned, for any reason

=back

=cut

sub getSession {}

=pod

=item getSessions()

Return an array containing the active Sessions managed by this
SessionManager.

=cut

sub getSessions {}

=pod

=item remove($session)

Remove this Session from the active Sessions managed by this
SessionManager.

B<Parameters:>

=over

=item $session

the B<Wombat::Session> to remove

=back

=cut

sub remove {}

=pod

=back

=head1 LIFECYCLE METHODS

=over

=item start()

Prepare for active use of this SessionManager. This method should be
called before any of the public methods of the SessionManager are
utilized.

B<Throws:>

=over

=item B<Wombat::LifecycleException>

if the SessionManager has already been started

=back

=cut

sub start {
    my $self = shift;

    if ($self->{started}) {
        my $msg = "start: session manager already started";
        Wombat::LifecycleException->throw($msg);
    }

    $self->{started} = 1;
    $self->log(sprintf("%s started", $self->getName()), undef, 'INFO');

    return 1;
}

=pod

=item stop()

Gracefully terminate active use of this SessionManager. Once this
method has been called, no public methods of the SessionManager should
be utilized.

B<Throws:>

=over

=item B<Wombat::LifecycleException>

if the SessionManager is not started

=back

=cut

sub stop {
    my $self = shift;

    unless ($self->{started}) {
        my $msg = "stop: session manager not started";
        Wombat::LifecycleException->throw($msg);
    }

# XXX: can't expire active sessions! when using the Apache connector
# and shared memory cache, there's no good way to do it. you can't do
# it at child exit time, cos the first time a child exits, all cached
# sessions will be invalidated. you apparently can't do it at server
# shutdown, cos i'm getting all kinds of weird behavior.

#      # expire all active sessions
#      for my $session ($self->getSessions()) {
#          # skip already expired sessions
#          next unless $session->isValid();

#          warn "expiring session id [", $session->getId(), "]: $session\n";
#          $session->expire();
#      }

    undef $self->{started};
    $self->log(sprintf("%s stopped", $self->getName()), undef, 'DEBUG');

    return 1;
}

=pod

=back

=cut

# private methods

sub generateSessionId {
    my $self = shift;

    for (my $i=0; $i < 16; $i++) {
        $self->{digest}->add(int rand 2<<15); # XXX: get a good random value!
    }

    return $self->{digest}->hexdigest();
}

sub log {
    my $self = shift;

    $self->{container}->log(@_) if $self->{container};

    return 1;
}

1;
__END__

=pod

=head1 SEE ALSO

L<Wombat::Container>,
L<Wombat::Core::Session>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
