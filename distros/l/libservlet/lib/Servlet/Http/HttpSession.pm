# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::Http::HttpSession;

$VERSION = 0;

1;
__END__

=pod

=head1 NAME

Servlet::Http::HttpSession - HTTP session interface

=head1 SYNOPSIS

  for my $name ($session->getAttributeNames()) {
      my $value = $session->getAttribute($name);
      # or
      $session->removeAttribute($name);
  }

  my $time = $session->getCreationTime();

  my $id = $session->getId();

  my $time = $session->getLastAccessedTime();

  my $timeout = $session->getMaxInactiveInterval();

  $session->invalidate();

  my $bool = $session->isNew();

  $session->setAttributre($name, $value);

  $session->setMaxInactiveInterval($timeout);

=head1 DESCRIPTION

Provides a way to identify a user across more than one page request or
site visit and to store information about that user.

The servlet container uses this interface to create a session between
an HTTP client and an HTTP server. The session persists for a
specified time period, across more than one connection or page request
from the user. A session usually corresponds to one user, who may
visit a site many times. The server can maintain a session in many
ways such as using cookies or rewriting URLs.

This interface allows servlets to view and manipulate information
about a session, such as the session identifier, creation time and
last accessed time, and to bind objects to sessions, allowing user
information to persist across multiple user connections.

When an application stores an object in or removes an object from a
session, the session checks whether the object implements
B<Servlet::Http::HttpSessionBindingListener>. If it does, the servlet
notifies the object that it has been bound to or unbound from the
session. Notifications are sent after the binding methods
complete. For sessions that are invalidated or expire, notifications
are sent after the session has been invalidated or expired.

When a container migrates a session between intepreters in a
distributed container setting, all session attributes implementing
B<Servlet::Http::HttpSessionActivationListener> are notified.

A servlet should be able to handle cases in which the client does not
choose to join a session, such as when cookies are intentionally
turned off. Until the client joins the session, C<isNew()> returns
true. If the client chooses not to join the session, C<getSession()>
will return a different session on each request, and C<isNew()> will
always return true.

Session information is scoped only to the current web application
(B<Servlet::ServletContext>), so information stored in one context
will not be directly visible in another.

=head1 METHODS

=over

=item getAttribute($name)

Returns the object bound with the specified name in this session, or
I<undef> if no object is bound under the name.

B<Parameters:>

=over

=item I<$name>

the name of the object

=back

B<Throws:>

=over

=item B<Servlet::Util::IllegalStateException>

if this method is called on an invalidated session

=back

=item getAttributeNames()

Returns an array containing the names of all the objects bound to this
session, or an empty array if there are no bound objects.

B<Throws:>

=over

=item B<Servlet::Util::IllegalStateException>

if this method is called on an invalidated session

=back

=item getCreationTime()

Returns the time when this session was created, measured in seconds
since the epoch.

B<Throws:>

=over

=item B<Servlet::Util::IllegalStateException>

if this method is called on an invalidated session

=back

=item getId()

Returns the unique identifier assigned to this session. The identifier
is assigned by the servlet container and is implementation dependent.

=item getLastAccessedTime()

Returns the last time the client sent a request associated with this
session, as the number of seconds since the epoch, and marked by the
time the container received the request.

Actions that your application takes, such as getting or setting a
value associated with the session, do not affect the access time.

=item getMaxInactiveInterval()

Returns the maximum time interval (in seconds) that the servlet
container will keep this session open between client accesses. After
this interval, the servlet container will invalidate the session. The
maximum time interval can be set with C<setMaxInactiveInterval()>. A
negative time indicates the session should never time out.

=item invalidate()

Invalidates this session, then unbinds any objects bound to it.

B<Throws:>

=over

=item B<Servlet::Util::IllegalStateException>

if this method is called on an invalidated session

=back

=item isNew()

Returns true fi the client does not yet know about the session or if
the client chooses not to join the session. For example, if the server
used only cookie-based sessions, and the client had disabled the use
of cookies, then a session would be new on each request.

B<Throws:>

=over

=item B<Servlet::Util::IllegalStateException>

if this method is called on an invalidated session

=back

=item removeAttribute($name)

Removes the object bound with the specified name from this session. If
the session does not have an object bound with the specified name,
this method does nothing.

After this method executes, and if the object implements
B<Servlet::Http::HttpSessionBindingListener>, the container calls
C<valueUnbound()> on the object.

B<Parameters:>

=over

=item I<$name>

the name of the object

=back

B<Throws:>

=over

=item B<Servlet::Util::IllegalStateException>

if this method is called on an invalidated session

=back

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

=item I<$name>

the name to which the object is bound

=item I<$value>

the object to be bound

=back

B<Throws:>

=over

=item B<Servlet::Util::IllegalStateException>

if this method is called on an invalidated session

=back

=item setMaxInactiveInterval($interval)

Specifies the time, in seconds, between client requests before the
servlet container will invalidate this session. A negative indicates
the session should never timeout.

B<Parameters:>

=over

=item I<$interval>

the number of seconds

=back

=back

=head1 SEE ALSO

L<Servlet::Http::HttpSessionActivationListener>,
L<Servlet::Http::HttpSessionBindingListener>,
L<Servlet::Http::HttpSessionContext>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
