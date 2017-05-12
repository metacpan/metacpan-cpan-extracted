use strict;
package Web::Authenticate::Session::Storage::Handler::SQL;
$Web::Authenticate::Session::Storage::Handler::SQL::VERSION = '0.011';
use Mouse;
use Carp;
use DateTime;
use Digest::SHA;
use DBIx::Raw;
use Web::Authenticate::Digest;
use Web::Authenticate::IpAddressProvider::EnvIpAddressProvider;
use Web::Authenticate::UserAgentProvider::EnvUserAgentProvider;
use Web::Authenticate::Session;
use Web::Authenticate::User::Storage::Handler::SQL;
#ABSTRACT: Implementation of Web::Authenticate::Session::Storage::Handler::Role that can be used with MySQL or SQLite.

with 'Web::Authenticate::Session::Storage::Handler::Role';



has user_storage_handler => (
    does => 'Web::Authenticate::User::Storage::Handler::Role',
    is => 'ro',
    required => 1,
    lazy => 1,
    default => sub {
        my ($self) = @_;
        Web::Authenticate::User::Storage::Handler::SQL->new(dbix_raw => $self->dbix_raw);
    },
);


has sessions_table => (
    isa => 'Str',
    is => 'ro',
    required => 1,
    default => 'sessions',
);


has session_id_field => (
    isa => 'Str',
    is => 'ro',
    required => 1,
    default => 'session_id',
);


has user_id_field => (
    isa => 'Str',
    is => 'ro',
    required => 1,
    default => 'user_id',
);


has require_same_user_agent => (
    isa => 'Bool',
    is => 'ro',
    required => 1,
    default => undef,

);


has require_same_ip_address => (
    isa => 'Bool',
    is => 'ro',
    required => 1,
    default => undef,
);


has digest => (
    does => 'Web::Authenticate::Digest::Role',
    is => 'ro',
    required => 1,
    default => sub { Web::Authenticate::Digest->new },
);


has user_agent_provider => (
    does => 'Web::Authenticate::UserAgentProvider::Role',
    is => 'ro',
    default => sub { Web::Authenticate::UserAgentProvider::EnvUserAgentProvider->new },
);


has ip_address_provider => (
    does => 'Web::Authenticate::IpAddressProvider::Role',
    is => 'ro',
    default => sub { Web::Authenticate::IpAddressProvider::EnvIpAddressProvider->new },
);


has user_agent_field => (
    isa => 'Str',
    is => 'ro',
    required => 1,
    default => 'user_agent',
);


has ip_address_field => (
    isa => 'Str',
    is => 'ro',
    required => 1,
    default => 'ip_address',
);


has expires_field => (
    isa => 'Str',
    is => 'ro',
    required => 1,
    default => 'expires',
);


has dbix_raw => (
    isa => 'DBIx::Raw',
    is => 'ro',
    required => 1,
);


has columns => (
    isa => 'ArrayRef',
    is => 'ro',
    required => 1,
    default => sub { [] },
);


has session_id_digest_hex => (
    isa => 'CodeRef',
    is => 'ro',
    required => 1,
    default => sub { \&Digest::SHA::sha512_hex },
);


sub store_session {
    my ($self, $user, $session_id, $expires, $session_values) = @_;
    croak "must provide user" unless $user;
    croak "must provide session_id" unless $session_id;
    croak "must provide valid expires" unless $expires or $expires < 1;

    my $sessions_table = $self->sessions_table;
    my $user_id_field = $self->user_id_field;
    my $session_id_field = $self->session_id_field;
    my $expires_field = $self->expires_field;

    $session_values ||= {};
    $session_values->{$user_id_field} = $user->id;
    $session_values->{$session_id_field} = $self->session_id_digest_hex->($session_id);
    $session_values->{$expires_field} = $expires;

    if ($self->require_same_user_agent) {
       $session_values->{$self->user_agent_field} = $self->digest->generate($self->user_agent_provider->get_user_agent); 
    }

    if ($self->require_same_ip_address) {
       $session_values->{$self->ip_address_field} = $self->digest->generate($self->ip_address_provider->get_ip_address); 
    }

    $self->dbix_raw->insert(href => $session_values, table => $sessions_table);

    my $selection = $self->_get_selection($user_id_field, $session_id_field, $expires_field);
    my $session = $self->dbix_raw->raw("SELECT $selection FROM $sessions_table WHERE $session_id_field = ?", $self->session_id_digest_hex->($session_id));

    unless ($session) {
        carp "failed to insert session to database";
        return;
    }

    return Web::Authenticate::Session->new(id => $session_id, expires => $session->{$expires_field}, user => $user, row => $session);
}


sub load_session {
    my ($self, $session_id) = @_;
    croak "must provide session_id" unless $session_id;

    my $sessions_table = $self->sessions_table;
    my $user_id_field = $self->user_id_field;
    my $session_id_field = $self->session_id_field;
    my $expires_field = $self->expires_field;
    my $user_agent_field = $self->user_agent_field;
    my $ip_address_field = $self->ip_address_field;

    my $now = DateTime->now->epoch;

    my @select_args;
    push @select_args, ($user_id_field, $session_id_field, $expires_field);

    if ($self->require_same_user_agent) {
        push @select_args, $user_agent_field;
    }

    if ($self->require_same_ip_address) {
        push @select_args, $ip_address_field;
    }

    my $selection = $self->_get_selection(@select_args);
    my $session = $self->dbix_raw->raw("SELECT $selection FROM $sessions_table WHERE $session_id_field = ? AND $expires_field >= $now", $self->session_id_digest_hex->($session_id));

    unless ($session) {
        return;
    }

    if ($self->require_same_user_agent) {
        my $user_agent = $session->{$user_agent_field};
        unless ($user_agent) {
            croak "there should be a user agent for session $session_id with digest_hex of " . $self->session_id_digest_hex->($session_id);
        }
        unless ($self->digest->validate($user_agent, $self->user_agent_provider->get_user_agent)) {
            return;
        }
    }

    if ($self->require_same_ip_address) {
        my $ip_address = $session->{$ip_address_field};
        unless ($ip_address) { 
            croak "there should be an ip address for session $session_id with digest_hex of " . $self->session_id_digest_hex->($session_id);
        }
        unless ($self->digest->validate($ip_address, $self->ip_address_provider->get_ip_address)) {
            return;
        }
    }

    my $user = $self->user_storage_handler->load_user_by_id($session->{$user_id_field});

    unless ($user) {
        carp "failed to load user from database";
        return;
    }

    return Web::Authenticate::Session->new(id => $session_id, expires => $session->{$expires_field}, user => $user, row => $session);
}


sub delete_session {
    my ($self, $session_id) = @_;
    croak "must provide session_id" unless $session_id;

    my $sessions_table = $self->sessions_table;
    my $session_id_field = $self->session_id_field;
    $self->dbix_raw->raw("DELETE FROM $sessions_table WHERE $session_id_field = ?", $self->session_id_digest_hex->($session_id));
}


sub invalidate_user_sessions {
    my ($self, $user) = @_;
    croak "must provide user" unless $user;

    my $sessions_table = $self->sessions_table;
    my $user_id_field = $self->user_id_field;
    $self->dbix_raw->raw("DELETE FROM $sessions_table WHERE $user_id_field = ?", $user->id);
}


sub update_expires {
    my ($self, $session_id, $expires) = @_;
    croak "must provide session_id" unless $session_id;
    croak "must provide expires" unless $expires;

    my $sessions_table = $self->sessions_table;
    my $session_id_field = $self->session_id_field;
    my $expires_field = $self->expires_field;
    $self->dbix_raw->raw("UPDATE $sessions_table SET $expires_field = ? WHERE $session_id_field = ?", $expires, $self->session_id_digest_hex->($session_id));
}

sub _get_selection {
    my ($self, @columns) = @_;

    die "columns required" unless @columns;

    my $selection = join ',', @columns;

    if (@{$self->columns}) {
        $selection .= ',' . join ',', @{$self->columns}; 
    }

    return $selection;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Web::Authenticate::Session::Storage::Handler::SQL - Implementation of Web::Authenticate::Session::Storage::Handler::Role that can be used with MySQL or SQLite.

=head1 VERSION

version 0.011

=head1 DESCRIPTION

This L<Web::Authenticate::Session::Storage::Handler::Role> is meant to be used with a very specific table structure:

    CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTO_INCREMENT,
        user_id INTEGER NOT NULL UNIQUE,
        session_id VARCHAR(255) NOT NULL UNIQUE,
        expires INTEGER NOT NULL
    );

Other columns can exists, and the names of the table and column can change. But at least these columns must exist
in order for this storage handler to work properly. Also, the primary key does not have to be an integer, and could
even be the session_id. Also, the user_id does not need to be unique if you want to allow multiple sessions for a
user by setting L<Web::Authenticate/allow_multiple_sessions_per_user> to true.

=head1 METHODS

=head2 user_storage_handler

Sets the L<Web::Authenticate::User::Storage::Handler::Role> to be used. This is required. Default is
L<Web::Authenticate::User::Storage::Handler::SQL> created with L</dbix_raw>.

=head2 sessions_table

Sets the name of the sessions table that will be used when querying the database. Default is 'sessions'.

=head2 session_id_field

Sets the name of the session id field that will be used when querying the database. Default is 'session_id'.

=head2 user_id_field

Sets the name of the user_id field that will be used when querying the database. Default is 'user_id'.

=head2 require_same_user_agent

A session id will only be valid from the user agent it was originally created on. If invalid, the session will be deleted in storage.
If this is set to true, a user agent field is required in the table. It should be a varchar 255 like so:

    CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTO_INCREMENT,
        user_id INTEGER NOT NULL UNIQUE,
        session_id VARCHAR(255) NOT NULL UNIQUE,
        user_agent VARCHAR(255),
        expires INTEGER NOT NULL
    );

See L</user_agent_field> to change the default name of the field.

=head2 require_same_ip_address

A session id will only be valid from the ip address it was originally created from. If invalid, the session will be deleted in storage.
If this is set to true, an ip address field is required in the table. It should be a varchar 255 like so:

    CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTO_INCREMENT,
        user_id INTEGER NOT NULL UNIQUE,
        session_id VARCHAR(255) NOT NULL UNIQUE,
        ip_address VARCHAR(255),
        expires INTEGER NOT NULL
    );

See L</ip_address_field> to change the default name of the field.

=head2 digest

Sets the L<Web::Authenticate::Digest::Role> that is used for user agents if L</require_same_user_agent> is set to true or ip addresses if 
L</require_same_ip_address> is set to true. Default is L<Web::Authenticate::Digest>.

=head2 user_agent_provider

Sets the object that does L<Web::Authenticate::UserAgentProvider::Role>. Default is L<Web::Authenticate::UserAgentProvider::EnvUserAgentProvider>.

=head2 ip_address_provider

Sets the object that does L<Web::Authenticate::IpAddressProvider::Role>. Default is L<Web::Authenticate::IpAddressProvider::EnvIpAdderssProvider>.

=head2 user_agent_field

Sets the name of the user agent field if L</require_same_user_agent> is set to 1. Default is 'user_agent'.

=head2 ip_address_field

Sets the name of the ip address field if L</require_same_ip_address> is set to 1. Default is 'ip_address'.

=head2 expires_field

Sets the name of the expires time field that will be used when querying the database. Default is 'expires'.

=head2 dbix_raw

Sets the L<DBIx::Raw> object that will be used to query the database. This is required with no default.

=head2 columns

The columns to select. At a minimum, L</session_id_field>, L</user_id_field>, and L</expires_field> will always be selected.

    $storage_handler->columns([qw/session_data/]);

Default is an empty array ref.

=head2 session_id_digest_hex

This is a subroutine reference to the digest hex that will be used when storing the session id.
Default is L<Digest::SHA::sha512_hex|Digest::SHA>.

=head2 store_session

Takes in user, session_id, expires, and any additional values for columns in a hash and a session with those values is created.
Returns a L<Web::Authenticate::Session> with any values from L</columns> stored in L<Web::Authenticate::Session/row>.

    my $session_values => {
        session_data => $session_data,
    };
    my $session = $session_storage_handler->store_session($user, $session_id, $expires, $session_values);

    # if you need no extra user values in the row
    my $session = $storage_handler->store_session($user, $session_id, $expires);

=head2 load_session

Loads a L<Web::Authenticate::Session> by session_id. If the session exists, the session is returned.
Otherwise, undef is returned. Undef will also be returned if the session is expires, or if the user agent or ip address don't match
if L</require_same_user_agent> or L</require_same_ip_address> are set. 
Any additional L</columns> will be stored in L<Web::Authenticate::Session/row>. 

    my $session = $session_storage_handler->load_session($session_id);

=head2 delete_session

Deletes a session from storage.

    $session_storage_handler->delete_session($session_id);

=head2 invalidate_user_sessions

Invalidates (deletes) any user sessions for user.

    $session_storage_handler->invalidate_user_sessions($user);

=head2 update_expires

Updates the expires time for the session with the session id session_id.

    $session_storage_handler->update_expires($session_id, $expires);

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
