# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Session;

use base qw(Servlet::Http::HttpSession);

$VERSION = 0;

1;
__END__

=pod

=head1 NAME

Wombat::Session - internal session interface

=head1 SYNOPSIS

=head1 DESCRIPTION

This interface extends B<Servlet::Http::HttpSession> to provide
fields and methods accessible only to the container.

=head1 ACCESSOR METHODS

=over

=item getAuthType()

Return the authentication type used to authenticate the cached
principal, if any.

=item setAuthType($authType)

Set the authentication type used to authenticate the cached principal,
if any.

B<Parameters:>

=over

=item $authType

the authentication type

=back

=item setCreationTime(time)

Set the creation time for this Session. This method is called by the
SessionManager when a Session instance is created or an existing
Session instance is reused.

B<Parameters:>

=over

=item $time

the creation time, in seconds since the epoch

=back

=item setId($id)

Set the session identifier for this Session.

B<Parameters:>

=over

=item $id

the session identifier

=back

=item setNew($flag)

Set a flag specifying whether or not the session is newly created.

B<Parameters:>

=over

=item $flag

the boolean value to set

=back

=item getPrincipal()

Return the authenticated principal for this Session, or C<undef> if
there is none.

=item setPrincipal($principal)

Set the authenticated principal for this Session.

B<Parameters:>

=over

=item $principal

the new principal

=back

=item getSession()

Return the HttpSession which acts as a facade for this Session to
servlet applications.

=item getSessionManager()

Return the SessionManager which manages this Session.

=item setSessionManager($manager)

Set the SessionManager which manages this Session.

B<Parameters:>

=over

=item $manager

the B<Wombat::SessionManager>

=back

=item isValid()

Return a flag specifying whether or not the session is valid.

=item setValid($flag)

Set a flag specifying whether or not the session is valid.

B<Parameters:>

=over

=item $flag

the boolean value to set

=back

=back

=head1 PUBLIC METHODS

=over

=item access()

Update the accessed time information for this Session. This method
should be called by the Application when processing a Request, even if
the Application does not reference it.

=item expire()

Perform the internal processing required to invalidate this session,
without triggering an exception if the session has already expired.

=item recycle()

Release all object references and initialize instances variables in
preparation for use or reuse of this object.

=back

=head1 SEE ALSO

L<Servlet::Http::HttpSession>,
L<Wombat::SessionManager>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
