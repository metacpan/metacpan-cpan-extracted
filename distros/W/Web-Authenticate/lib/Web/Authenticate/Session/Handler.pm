use strict;
package Web::Authenticate::Session::Handler;
$Web::Authenticate::Session::Handler::VERSION = '0.012';
use Mouse;
use Carp;
use DateTime;
use Session::Token;
use Web::Authenticate::Cookie::Handler;
#ABSTRACT: The default implementation of Web::Authentication::Session::Handler::Role.

with 'Web::Authenticate::Session::Handler::Role';


has session_storage_handler => (
    does => 'Web::Authenticate::Session::Storage::Handler::Role',
    is => 'ro',
    required => 1,
);


has cookie_handler => (
    does => 'Web::Authenticate::Cookie::Handler::Role',
    is => 'ro',
    required => 1,
    default => sub { Web::Authenticate::Cookie::Handler->new },
);


has session_expires_in_seconds => (
    isa => 'Int',
    is => 'ro',
    required => 1,
    default => 86400,
);


has session_id_cookie_name => (
    isa => 'Str',
    is => 'ro',
    required => 1,
    default => 'session_id',
);


sub create_session {
    my ($self, $user) = @_;
    croak "must provide user" unless $user;

    my $session_id = Session::Token->new(entropy => 256)->get;
    my $session = $self->session_storage_handler->store_session($user, $session_id, $self->_get_expires);

    return unless $session;

    $self->_set_session_cookie($session_id);

    return $session;
}


sub delete_session {
    my ($self, $session_id) = @_;

    $session_id ||= $self->_get_session_id;
    return unless $session_id;

    $self->session_storage_handler->delete_session($session_id);
    $self->_delete_session_cookie;
}


sub update_expires {
    my ($self) = @_;
    my $session_id = $self->_get_session_id;

    return unless $session_id;

    $self->session_storage_handler->update_expires($session_id, $self->_get_expires);
    $self->_set_session_cookie($session_id);
}


sub invalidate_current_session {
    my ($self) = @_;

    my $session_id = $self->_get_session_id;
    if ($session_id) {
        $self->session_storage_handler->delete_session($session_id);
    }
}


sub invalidate_user_sessions {
    my ($self, $user) = @_;
    $self->session_storage_handler->invalidate_user_sessions($user);
}


sub get_session {
    my ($self) = @_;

    my $session_id = $self->_get_session_id;

    return unless $session_id;

    my $session = $self->session_storage_handler->load_session($session_id);

    unless ($session) {
        $self->delete_session($session_id);
    }

    return $session;
}

sub _get_session_id {
    my ($self) = @_;
    return $self->cookie_handler->get_cookie($self->session_id_cookie_name);
}

sub _get_expires {
    my ($self) = @_;
    return DateTime->now->add(seconds => $self->session_expires_in_seconds)->epoch;
}

sub _set_session_cookie {
    my ($self, $session_id) = @_;
    $self->cookie_handler->set_cookie($self->session_id_cookie_name, $session_id, $self->session_expires_in_seconds);
}

sub _delete_session_cookie {
    my ($self) = @_;
    $self->cookie_handler->delete_cookie($self->session_id_cookie_name);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Web::Authenticate::Session::Handler - The default implementation of Web::Authentication::Session::Handler::Role.

=head1 VERSION

version 0.012

=head1 METHODS

=head2 session_storage_handler

Sets the object that does L<Web::Authenticate::Sesssion::Storage::Handler::Role>. This is required an has no default.

=head2 cookie_handler

Sets the object that does L<Web::Authenticate::Cookie::Handler::Role>. This is required. Default is L<Web::Authenticate::Cookie::Handler>.

=head2 session_expires_in_seconds

Sets the amount of time a session will expire in after last successful page load. Default is 86,400 (one day).

=head2 session_id_cookie_name

Sets the session_id cookie name. Default is 'session_id'.

=head2 create_session

Creates session for the user and stores the cookie for the session in the user's browser.

=head2 delete_session

Deletes the current session.

    $session_handler->delete_session;

=head2 update_expires

Updates the expires time for the logged in user to now + L</session_expires_in_seconds>.

=head2 invalidate_current_session

Invalidates the user's current session if there is one.

=head2 invalidate_user_sessions

Deletes all sessions for user.

=head2 get_session

Returns the session for the logged in user. Returns undef if there is no session. If an invalid
session is found in the user's cookies, that session will be deleted from their cookies. If the user
has a session id in their browser that is not valid, the session id will be deleted from their cookie
and from storage.

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
