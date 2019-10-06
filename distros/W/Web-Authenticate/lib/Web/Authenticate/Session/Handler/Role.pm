use strict;
package Web::Authenticate::Session::Handler::Role;
$Web::Authenticate::Session::Handler::Role::VERSION = '0.012';
use Mouse::Role;
#ABSTRACT: A Mouse::Role that defines what methods a Web::Authenticate::Session::Handler object should contain.


requires 'create_session';


requires 'delete_session';


requires 'update_expires';


requires 'invalidate_current_session';


requires 'invalidate_user_sessions';


requires 'get_session';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Web::Authenticate::Session::Handler::Role - A Mouse::Role that defines what methods a Web::Authenticate::Session::Handler object should contain.

=head1 VERSION

version 0.012

=head1 METHODS

=head2 create_session

Creates a session for user. Returns an object that does L<Web::Authenticate::Session::Role>.

    my $session = $session_handler->create_session($user);

=head2 delete_session

Deletes the current session.

    $session_handler->delete_session;

=head2 update_expires

Updates the expires time for session. Returns an object that does L<Web::Authenticate::Session::Role>.

    my $updated_session = $session_handler->update_expires($session);

=head2 invalidate_current_session

Invalidates the current session if the user has one.

    $session_handler->invalidate_current_session;

=head2 invalidate_user_sessions

Invalidates all sessions for a user.

    $session_handler->invalidate_user_sessions($user);

=head2 get_session

Returns the session for the current user. Returns undef if there is no session.

    my $session = $session_handler->get_session;

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
