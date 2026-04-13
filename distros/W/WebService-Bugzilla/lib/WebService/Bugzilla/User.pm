#!/usr/bin/false
# ABSTRACT: Bugzilla User object and service
# PODNAME: WebService::Bugzilla::User

package WebService::Bugzilla::User 0.001;
use strictures 2;
use Moo;
use namespace::clean;

extends 'WebService::Bugzilla::Object';
with 'WebService::Bugzilla::Role::Updatable';

sub _unwrap_key { 'users' }

has can_login      => (is => 'ro', lazy => 1, builder => '_build_can_login');
has creation_time  => (is => 'ro', lazy => 1, builder => '_build_creation_time');
has email          => (is => 'ro', lazy => 1, builder => '_build_email');
has groups         => (is => 'ro', lazy => 1, builder => '_build_groups');
has is_blocked     => (is => 'ro', lazy => 1, builder => '_build_is_blocked');
has is_enabled     => (is => 'ro', lazy => 1, builder => '_build_is_enabled');
has login_name     => (is => 'ro', lazy => 1, builder => '_build_login_name');
has name           => (is => 'ro', lazy => 1, builder => '_build_name');
has real_name      => (is => 'ro', lazy => 1, builder => '_build_real_name');
has saved_searches => (is => 'ro', lazy => 1, builder => '_build_saved_searches');

around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;
    my $args = $class->$orig(@args);
    if (exists $args->{login} && !exists $args->{login_name}) {
        $args->{login_name} = delete $args->{login};
    }
    return $args;
};

my @attrs = qw(
    can_login
    creation_time
    email
    groups
    is_blocked
    is_enabled
    login_name
    name
    real_name
    saved_searches
);

for my $attr (@attrs) {
    my $build = "_build_$attr";
    {
        no strict 'refs';
        *{ $build } = sub {
            my ($self) = @_;
            my $id_or_name = $self->_api_data->{login_name} // $self->_api_data->{email} // $self->id;
            $self->_fetch_full($self->_mkuri("user/$id_or_name"));
            return $self->_api_data->{$attr};
        };
    }
}

sub create {
    my ($self, %params) = @_;
    my $res = $self->client->post($self->_mkuri('user'), \%params);
    return $self->new(
        client => $self->client,
        _data  => { %params, id => $res->{id} },
    );
}

sub get {
    my ($self, $id_or_name) = @_;
    my $res = $self->client->get($self->_mkuri("user/$id_or_name"));
    return unless $res->{users} && @{ $res->{users} };
    my $data = $res->{users}[0];
    if (exists $data->{login} && !exists $data->{login_name}) {
        $data->{login_name} = delete $data->{login};
    }
    return $self->new(
        client => $self->client,
        _data  => $data,
    );
}

sub login {
    my ($self, %params) = @_;
    return $self->client->post($self->_mkuri('login'), \%params);
}

sub logout {
    my ($self) = @_;
    return $self->client->post($self->_mkuri('logout'), {});
}

sub search {
    my ($self, %params) = @_;
    my $res = $self->client->get($self->_mkuri('user'), \%params);
    return [
        map {
            my $data = $_;
            if (exists $data->{login} && !exists $data->{login_name}) {
                $data->{login_name} = delete $data->{login};
            }
            $self->new(
                client => $self->client,
                _data  => $data
            )
        }
        @{ $res->{users} // [] }
    ];
}

sub valid_login {
    my ($self, %params) = @_;
    my $res = $self->client->get($self->_mkuri('valid_login'), \%params);
    return $res->{result};
}

sub whoami {
    my ($self) = @_;
    my $res = $self->client->get($self->_mkuri('whoami'));
    my $data = $res;
    if (exists $data->{login} && !exists $data->{login_name}) {
        $data->{login_name} = delete $data->{login};
    }
    my $obj = $self->new(
        client => $self->client,
        _data  => $data,
    );
    $obj->_is_loaded(1);
    return $obj;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Bugzilla::User - Bugzilla User object and service

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use WebService::Bugzilla;

    my $bz = WebService::Bugzilla->new(
        base_url => 'https://bugzilla.example.com',
        api_key  => 'your-api-key-here',
    );

    # Get current logged-in user
    my $me = $bz->user->whoami();
    say 'Logged in as: ', $me->login_name;

    # Get a user by ID or email
    my $user = $bz->user->get('user@example.com');
    if ($user) {
        say 'Name: ', $user->real_name;
        say 'Email: ', $user->email;
        say 'Enabled: ', $user->is_enabled ? 'yes' : 'no';
    }

    # Search for users
    my $users = $bz->user->search(match => 'admin');
    for my $u (@{$users}) {
        say $u->login_name;
    }

    # Create a new user
    my $new = $bz->user->create(
        email     => 'newuser@example.com',
        real_name => 'New User',
    );

    # Update a user
    my $updated = $bz->user->update('user@example.com',
        real_name  => 'Updated Name',
        is_enabled => 1,
    );

    # Validate credentials
    my $valid = $bz->user->valid_login(
        login    => 'user@example.com',
        password => 'secret',
    );
    say 'Credentials valid: ', $valid ? 'yes' : 'no';

    # Login (returns token)
    my $result = $bz->user->login(
        login    => 'user@example.com',
        password => 'secret',
    );
    say 'Token: ', $result->{token};

    # Logout
    $bz->user->logout();

=head1 DESCRIPTION

Provides access to the
L<Bugzilla User API|https://bmo.readthedocs.io/en/latest/api/core/v1/user.html>.
User objects expose account attributes and provide helpers to create, fetch,
search, update, and authenticate users.

Use C<< $bz->user >> to access the user service from a L<WebService::Bugzilla>
instance.

=head1 ATTRIBUTES

All attributes are read-only and lazy.

=over 4

=item C<can_login>

Boolean. Whether this user account can be used to log in.

=item C<creation_time>

When the user account was created (ISO 8601 datetime string).

=item C<email>

The user's email address.

=item C<groups>

Arrayref of groups this user belongs to.

=item C<id>

The unique user ID. Inherited from L<WebService::Bugzilla::Object>.

=item C<is_blocked>

Boolean. Whether this user has been blocked from logging in.

=item C<is_enabled>

Boolean. Whether this user account is enabled.

=item C<login_name>

The user's login name (usually an email address).

=item C<name>

Alias for C<login_name>.

=item C<real_name>

The user's full name (human-readable name).

=item C<saved_searches>

Arrayref of saved searches created by this user.

=back

=head1 METHODS

=head2 BUILDARGS

L<Moo> C<around> modifier.  Normalizes incoming construction parameters;
accepts C<login> as an alias for C<login_name>.

=head2 create

    my $user = $bz->user->create(
        email     => 'user@example.com',
        real_name => 'User Name',
    );

Create a new user account.  Requires C<email>.
See L<POST /rest/user|https://bmo.readthedocs.io/en/latest/api/core/v1/user.html#create-user>.

Returns a new L<WebService::Bugzilla::User> object.

=head2 get

    my $user = $bz->user->get('user@example.com');
    my $user = $bz->user->get(123);

Fetch a user by ID or email address.
See L<GET /rest/user/{id_or_name}|https://bmo.readthedocs.io/en/latest/api/core/v1/user.html#get-user>.

Returns a L<WebService::Bugzilla::User>, or C<undef> if not found.

=head2 login

    my $result = $bz->user->login(
        login    => 'user@example.com',
        password => 'password',
    );

Authenticate and obtain a login token.
See L<GET /rest/login|https://bmo.readthedocs.io/en/latest/api/core/v1/user.html#login>.

Returns a hashref with C<id>, C<token>, and other login information.

=head2 logout

    $bz->user->logout;

Log out the current session.
See L<GET /rest/logout|https://bmo.readthedocs.io/en/latest/api/core/v1/user.html#logout>.

=head2 search

    my $users = $bz->user->search(match => 'admin');

Search for users.
See L<GET /rest/user|https://bmo.readthedocs.io/en/latest/api/core/v1/user.html#get-user>.

Returns an arrayref of L<WebService::Bugzilla::User> objects.

=head2 update

    my $updated = $bz->user->update('user@example.com', real_name => 'New Name');
    my $updated = $user->update(real_name => 'New Name');

Update user properties.  Can be called as a class method with ID/email or
as an instance method.
See L<PUT /rest/user/{id}|https://bmo.readthedocs.io/en/latest/api/core/v1/user.html#update-user>.

Returns a L<WebService::Bugzilla::User> with updated data.

=head2 valid_login

    my $valid = $bz->user->valid_login(
        login    => 'user@example.com',
        password => 'password',
    );

Validate user credentials without creating a session.
See L<GET /rest/valid_login|https://bmo.readthedocs.io/en/latest/api/core/v1/user.html#valid-login>.

Returns true if the credentials are valid.

=head2 whoami

    my $me = $bz->user->whoami;

Return information about the currently authenticated user.
See L<GET /rest/whoami|https://bmo.readthedocs.io/en/latest/api/core/v1/user.html#who-am-i>.

Returns a L<WebService::Bugzilla::User> for the authenticated user.

=head1 SEE ALSO

L<WebService::Bugzilla> - main client

L<WebService::Bugzilla::UserDetail> - lightweight user detail objects

L<https://bmo.readthedocs.io/en/latest/api/core/v1/user.html> - Bugzilla User REST API

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
