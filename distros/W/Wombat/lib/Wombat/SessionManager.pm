# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::SessionManager;

$VERSION = 0;

1;
__END__

=pod

=head1 NAME

Wombat::SessionManager - internal session manager interface

=head1 SYNOPSIS

=head1 DESCRIPTION

This interface specifies a component that manages a pool of Sessions
for a Container.

=head1 ACCESSOR METHODS

=over

=item getContainer()

Return the Container for which this SessionManager manages Sessions.

=item setContainer($container)

Set the Container for which this SessionManager manages Sessions.

B<Parameters:>

=over

=item $container

the B<Wombat::Container>

=back

=item getMaxInactiveInterval()

Return the default maximum inactive interval in seconds for Sessions
created by this SessionManager.

=item setMaxInactiveInterval($interval)

Set the default maximum inactive interval for Sessions created by this
SessionManager.

B<Parameters:>

=over

=item $interval

the new interval, in seconds

=back

=item getName()

Return the display name of this SessionManager. Subclasses B<MUST>
override this method.

=back

=head1 PUBLIC METHODS

=over

=item add($session)

Add this Session to the set of active Sessions for this
SessionManager.

B<Parameters:>

=over

=item $session

the B<Wombat::Session> to be added

=back

=item createSession()

Construct and return a B<Wombat::Session>, based on the default
settings specified by this SessionManager's fields. The session id
will be assigned by this method.

B<Throws:>

=over

=item B<Servlet::Util::IllegalStateException>

if a new Session cannot be created for, any reason

=back

=item getSession($id)

Return the active Session managed by this SessionManager with the
specified id, or C<undef> if no session exists with that id or if the
session is not valid.

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

=item getSessions()

Return an array containing the active Sessions managed by this
SessionManager.

=item remove($session)

Remove this Session from the active Sessions managed by this
SessionManager.

B<Parameters:>

=over

=item $session

the B<Wombat::Session> to be added

=back

=back

=head1 SEE ALSO

L<Wombat::Container>,
L<Wombat::Session>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
