# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Core::Session;

=pod

=head1 NAME

Wombat::Core::Session - internal session class

=head1 SYNOPSIS

=head1 DESCRIPTION

Core implementation of B<Wombat::Session> and
B<Servlet::Http::HttpSession>.

=cut

use base qw(Wombat::Session);
use fields qw(authType expiring facade sessionManager principal valid);
use fields qw(thisAccessedTime attributes creationTime id lastAccessedTime);
use fields qw(maxInactiveInterval new);
use strict;
use warnings;

use Servlet::Http::HttpSessionBindingEvent ();
use Servlet::Util::Exception ();
use Wombat::Core::SessionFacade ();
use Wombat::Globals ();

=pod

=head1 CONSTRUCTOR

=over

=item new()

Construct and return a B<Wombat::Core::Session> instance, initializing
fields appropriately.

  $self->SUPER::new();

=back

=cut

sub new {
    my $self = shift;

    $self = fields::new($self) unless ref $self;

    $self->recycle();

    return $self;
}

=pod

=head1 ACCESSOR METHODS

=over

=item getAttribute($name)

Returns the object bound with the specified name in this session, or
I<undef> if no object is bound under the name.

B<Parameters:>

=over

=item $name

the name of the object

=back

B<Throws:>

=over

=item B<Servlet::Util::IllegalStateException>

if this method is called on an invalidated session

=back

=cut

sub getAttribute {
    my $self = shift;
    my $name = shift;

    if (! $self->{expiring} && ! $self->{valid}) {
        my $msg = "getAttribute: invalid session";
        Servlet::Util::IllegalStateException->throw($msg);
    }

    return $self->{attributes}->{$name};
}

=pod

=item getAttributeNames()

Returns an array containing the names of all the objects bound to this
session, or an empty array if there are no bound objects.

B<Throws:>

=over

=item B<Servlet::Util::IllegalStateException>

if this method is called on an invalidated session

=back

=cut

sub getAttributeNames {
    my $self = shift;
    my $name = shift;

    if (! $self->{expiring} && ! $self->{valid}) {
        my $msg = "getAttribute: invalid session";
        Servlet::Util::IllegalStateException->throw($msg);
    }

    my @attributes = keys %{ $self->{attributes} };

    return wantarray ? @attributes : \@attributes;
}

=pod

=item removeAttribute($name)

Removes the object bound with the specified name from this session. If
the session does not have an object bound with the specified name,
this method does nothing.

After this method executes, and if the object implements
B<Servlet::Http::HttpSessionBindingListener>, the container calls
C<valueUnbound()> on the object.

B<Parameters:>

=over

=item $name

the name of the object

=back

B<Throws:>

=over

=item B<Servlet::Util::IllegalStateException>

if this method is called on an invalidated session

=back

=cut

sub removeAttribute {
    my $self = shift;
    my $name = shift;

    if (!$self->{expiring} && !$self->{valid}) {
        my $msg = "getAttribute: invalid session";
        Servlet::Util::IllegalStateException->throw($msg);
    }

    my $value = $self->{attributes}->{$name};
    if (defined $value) {
        delete $self->{attributes}->{$name};
    } else {
        return 1;
    }

    # notify unbound value if necessary
    if ($value && ref $value &&
        $value->isa('Servlet::Http::HttpSessionBindingListener')) {
        my $event = Servlet::Http::HttpSessionBindingEvent->new($self, $name,
                                                                $value);
        $value->valueUnbound($event);
    }

    # XXX: notify application event listeners

    return 1;
}

=pod

=item setAttribute($name, $value)

Binds an object to this session using the specified name. If an object
of the same name is already bound to the session, the object is
replaced.

After this method executes, and if the new object implements
B<Servlet::Http::HttpSessionBindingListener>, the container calls
C<valueBound()> on the object.

If a previously bound object was replaced, and it implements
B<Servlet::Http::HttpSessionBindingListener>, the container calls
C<valueUnbound()> on it.

B<Parameters:>

=over

=item $name

the name to which the object is bound

=item $value

the object to be bound

=back

B<Throws:>

=over

=item B<Servlet::Util::IllegalStateException>

if this method is called on an invalidated session

=back

=cut

sub setAttribute {
    my $self = shift;
    my $name = shift;
    my $value = shift;

    return $self->removeAttribute($name) unless defined $value;

    if (! $self->{expiring} && ! $self->{valid}) {
        my $msg = "getAttribute: invalid session";
        Servlet::Util::IllegalStateException->throw($msg);
    }

    my $unbound = $self->{attributes}->{$name};
    $self->{attributes}->{$name} = $value;

    # notify unbound value if necessary
    if ($unbound && ref $unbound &&
        $unbound->isa('Servlet::Http::HttpSessionBindingListener')) {
        my $event = Servlet::Http::HttpSessionBindingEvent->new($self, $name);
        $unbound->valueUnbound($event);
    }

    # notify bound value if necessary
    if (ref $value &&
        $value->isa('Servlet::Http::HttpSessionBindingListener')) {
        my $event = Servlet::Http::HttpSessionBindingEvent->new($self, $name,
                                                                $unbound);
        $value->valueBound($event);
    }

    # XXX: notify application event listeners

    return 1;
}

=pod

=item getAuthType()

Return the authentication type used to authenticate the cached
principal, if any.

=cut

sub getAuthType {
    my $self = shift;

    return $self->{authType};
}

=pod

=item setAuthType($authType)

Set the authentication type used to authenticate the cached principal,
if any.

B<Parameters:>

=over

=item $authType

the authentication type

=back

=cut

sub setAuthType {
    my $self = shift;
    my $type = shift;

    $self->{authType} = $type;

    return 1;
}

=pod

=item getCreationTime()

Return the creation time for this Session, in seconds since the epoch.

B<Throws:>

=over

=item B<Servlet::Util::IllegalStateException>

if this method is called on an invalidated session

=back

=cut

sub getCreationTime {
    my $self = shift;

    if (! $self->{expiring} && ! $self->{valid}) {
        my $msg = "getAttribute: invalid session";
        Servlet::Util::IllegalStateException->throw($msg);
    }

    return $self->{creationTime};
}

=pod

=item setCreationTime(time)

Set the creation time for this Session. This method is called by the
SessionManager when a Session instance is created or an existing
Session instance is reused.

B<Parameters:>

=over

=item $time

the creation time, in seconds since the epoch

=back

=cut

sub setCreationTime {
    my $self = shift;
    my $time = shift;

    $self->{creationTime} = $time;
    $self->{lastAccessedTime} = $time;
    $self->{thisAccessedTime} = $time;

    return 1;
}

=pod

=item getId()

Return the session identifier for this Session.

=cut

sub getId {
    my $self = shift;

    return $self->{id};
}

=pod

=item setId($id)

Set the session identifier for this Session.

B<Parameters:>

=over

=item $id

the session identifier

=back

=cut

sub setId {
    my $self = shift;
    my $id = shift;

    $self->{sessionManager}->remove($self) if
        defined $self->getId() && $self->{sessionManager};

    $self->{id} = $id;

    $self->{sessionManager}->add($self) if $self->{sessionManager};

    # XXX: notify application event listeners

    return 1;
}

=pod

=item getLastAccessedTime()

Return the last time the client sent a request associated with this
Session, as the number of seconds since the epoch. Actions taken by
servlet applications do not affect the last accessed time.

=cut

sub getLastAccessedTime {
    my $self = shift;

    return $self->{lastAccessedTime};
}

=pod

=item getMaxInactiveInterval()

Return the maximum inactive interval, in seconds, between client
requests before the servlet container will invalidate this Session. A
negative itnerval indicates that the session should never be
invalidated.

=cut

sub getMaxInactiveInterval {
    my $self = shift;

    return $self->{maxInactiveInterval};
}

=pod

=item setMaxInactiveInterval($interval)

Set the maximum inactive interval for the Session.

B<Parameters:>

=over

=item $interval

the new interval, in seconds

=back

=cut

sub setMaxInactiveInterval {
    my $self = shift;
    my $interval = shift;

    return $self->{maxInactiveInterval} = $interval;
}

=pod

=item isNew()

Returns true if the client does not yet know about the session or if
the client chooses not to join the session. For example, if the server
used only cookie-based sessions, and the client had disabled the use
of cookies, then a session would be new on each request.

B<Throws:>

=over

=item B<Servlet::Util::IllegalStateException>

if this method is called on an invalidated session

=back

=cut

sub isNew {
    my $self = shift;

    if (! $self->{expiring} && ! $self->{valid}) {
        my $msg = "getAttribute: invalid session";
        Servlet::Util::IllegalStateException->throw($msg);
    }

    return $self->{new};
}

=pod

=item setNew($flag)

Set a flag specifying whether or not the session is newly created.

B<Parameters:>

=over

=item $flag

the boolean value to set

=back

=cut

sub setNew {
    my $self = shift;
    my $flag = shift;

    $self->{new} = $flag;

    return 1;
}

=pod

=item getPrincipal()

Return the authenticated principal for this Session, or C<undef> if
there is none.

=cut

sub getPrincipal {
    my $self = shift;

    return $self->{principal};
}

=pod

=item setPrincipal($principal)

Set the authenticated principal for this Session.

B<Parameters:>

=over

=item $principal

the new principal

=back

=cut

sub setPrincipal {
    my $self = shift;
    my $principal = shift;

    $self->{principal} = $principal;

    return 1;
}

=pod

=item getSession()

Return the HttpSession which acts as a facade for this Session to
servlet applications.

=cut

sub getSession {
    my $self = shift;

    return $self->{facade};
}

=pod

=item getSessionManager()

Return the SessionManager which manages this Session.

=cut

sub getSessionManager {
    my $self = shift;

    return $self->{sessionManager};
}

=pod

=item setSessionManager($manager)

Set the SessionManager which manages this Session.

B<Parameters:>

=over

=item $manager

the B<Wombat::SessionManager>

=back

=cut

sub setSessionManager {
    my $self = shift;
    my $manager = shift;

    $self->{sessionManager} = $manager;

    return 1;
}

=pod

=item isValid()

Return a flag specifying whether or not the session is valid.

=cut

sub isValid {
    my $self = shift;

    return $self->{valid};
}

=pod

=item setValid($flag)

Set a flag specifying whether or not the session is valid.

B<Parameters:>

=over

=item $flag

the boolean value to set

=back

=cut

sub setValid {
    my $self = shift;
    my $flag = shift;

    $self->{valid} = $flag;

    return 1;
}

=pod

=back

=head1 PUBLIC METHODS

=over

=item access()

Update the accessed time information for this Session. This method
should be called by the Application when processing a Request, even if
the Application does not reference it.

=cut

sub access {
    my $self = shift;

    $self->{new} = undef;
    $self->{lastAccessedTime} = $self->{thisAccessedTime};
    $self->{thisAccessedTime} = time;

    return 1;
}

=pod

=item expire()

Perform the internal processing required to invalidate this session,
without triggering an exception if the session has already expired.

=cut

sub expire {
    my $self = shift;

    $self->{expiring} = 1;

    undef $self->{valid};
    $self->{sessionManager}->remove($self) if $self->{sessionManager};

    # unbind attributes
    for my $name ($self->getAttributeNames()) {
        $self->removeAttribute($name);
    }

    # XXX: notify application event listeners

    undef $self->{expiring};

    $self->recycle();

    return 1;
}

=pod

=item invalidate()

Invalidates this session, then unbinds any objects bound to it.

B<Throws:>

=over

=item B<Servlet::Util::IllegalStateException>

if this method is called on an invalidated session

=back

=cut

sub invalidate {
    my $self = shift;

    if (! $self->{expiring} && ! $self->{valid}) {
        my $msg = "getAttribute: invalid session";
        Servlet::Util::IllegalStateException->throw($msg);
    }

    $self->expire();

    return 1;
}

=pod

=item recycle()

Release all object references and initialize instances variables in
preparation for use or reuse of this object.

=cut

sub recycle {
    my $self = shift;

    # Wombat::Session fields
    $self->{authType} = undef;
    $self->{expiring} = undef;
    $self->{facade} = Wombat::Core::SessionFacade->new($self);
    $self->{sessionManager} = undef;
    $self->{principal} = undef;
    $self->{thisAccessedTime} = 0;
    $self->{valid} = undef;

    # Servlet::Http::HttpSession fields
    $self->{attributes} = {};
    $self->{creationTime} = 0;
    $self->{id} = undef;
    $self->{lastAccessedTime} = 0;
    $self->{maxInactiveInterval} = -1;
    $self->{new} = undef;

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

L<Wombat::Session>,
L<Wombat::SessionManager>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
