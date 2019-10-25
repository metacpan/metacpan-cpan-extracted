use strict;
package Web::Authenticate::Session::Storage::Handler::Role;
$Web::Authenticate::Session::Storage::Handler::Role::VERSION = '0.013';
use Mouse::Role;
#ABSTRACT: A Mouse::Role that defines what methods a Web::Authenticate::Session::Storage::Handler object should contain.


requires 'store_session';


requires 'load_session';


requires 'update_expires';


requires 'delete_session';


requires 'invalidate_user_sessions';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Web::Authenticate::Session::Storage::Handler::Role - A Mouse::Role that defines what methods a Web::Authenticate::Session::Storage::Handler object should contain.

=head1 VERSION

version 0.013

=head1 METHODS

=head2 create_session

Creates a session for user in storage. Returns a L<Web::Authenticate::Session::Role> upon success, undef
upon failure.

    my $session = $session_storage_handler->create_session($user, $session_id, $expires);

=head2 get_session

Gets the session with the session id $session_id, as long as it has not expired.

    my $session = $session_storage_handler->get_session($session_id);

=head2 update_expires

Updates the time a session expires.

    $session_storage_handler->update_expires($session_id, $expires);

=head2 delete_session

Deletes a session from storage.

    $session_storage_handler->delete_session($session_id);

=head2 invalidate_user_sessions

Updates the time a session expires.

    $session_storage_handler->invalidate_user_sessions($user);

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
