package WebService::Mattermost::V4::API::Resource::Users;

use Moo;

extends 'WebService::Mattermost::V4::API::Resource';
with    'WebService::Mattermost::V4::API::Resource::Role::View::User';

################################################################################

around [ qw(get_by_username check_mfa_by_username) ] => sub {
    my $orig     = shift;
    my $self     = shift;
    my $username = shift;

    unless ($username) {
        return $self->_error_return('Invalid or missing username parameter');
    }

    return $self->$orig($username, @_);
};

around [ qw(get_by_email send_password_reset_email) ] => sub {
    my $orig  = shift;
    my $self  = shift;
    my $email = shift;

    unless ($email) {
        return $self->_error_return('Invalid or missing email parameter');
    }

    return $self->$orig($email, @_);
};

around [ qw(
    disable_personal_access_token
    enable_personal_access_token
    get_user_access_token
) ] => sub {
    my $orig  = shift;
    my $self  = shift;
    my $token = shift;

    unless ($token) {
        return $self->_error_return('Invalid or missing token parameter');
    }

    return $self->$orig($token, @_);
};

################################################################################

sub login {
    my $self     = shift;
    my $username = shift;
    my $password = shift;

    return $self->_single_view_post({
        endpoint   => 'login',
        parameters => {
            login_id => $username,
            password => $password,
        },
    });
}

sub create {
    my $self = shift;
    my $args = shift;

    return $self->_post({
        parameters => $args,
        required   => [ qw(username password email) ],
    });
}

sub list {
    my $self = shift;
    my $args = shift;

    return $self->_get({ parameters => $args });
}

sub list_by_ids {
    my $self = shift;
    my $ids  = shift;

    return $self->_call({
        endpoint   => 'ids',
        method     => $self->post,
        parameters => $ids,
    });
}

sub list_by_usernames {
    my $self      = shift;
    my $usernames = shift;

    return $self->_post({
        endpoint   => 'usernames',
        parameters => $usernames,
    });
}

sub search {
    my $self = shift;
    my $args = shift;

    return $self->_post({
        endpoint   => 'search',
        parameters => $args,
        required   => [ 'term' ],
    });
}

sub autocomplete {
    my $self = shift;
    my $args = shift;

    return $self->_get({
        endpoint   => 'autocomplete',
        parameters => $args,
        required   => [ 'name' ],
    });
}

sub get_by_username {
    my $self     = shift;
    my $username = shift;

    return $self->_single_view_get({
        endpoint => 'username/%s',
        ids      => [ $username ],
    });
}

sub reset_password {
    my $self = shift;
    my $args = shift;

    return $self->_post({
        endpoint   => 'password/reset',
        parameters => $args,
        required   => [ qw(code new_password) ],
    });
}

sub check_mfa_by_username {
    my $self     = shift;
    my $username = shift;

    return $self->_post({
        endpoint   => 'mfa',
        parameters => {
            login_id => $username,
        },
    });
}

sub send_password_reset_email {
    my $self  = shift;
    my $email = shift;

    return $self->_post({
        endpoint   => 'password/reset/send',
        parameters => {
            email => $email,
        },
    });
}

sub get_by_email {
    my $self  = shift;
    my $email = shift;

    return $self->_get({
        endpoint => 'email/%s',
        ids      => [ $email ],
    });
}

sub get_user_access_token {
    my $self = shift;
    my $id   = shift;

    return $self->_get({
        endpoint => 'tokens/%s',
        ids      => [ $id ],
    });
}

sub disable_personal_access_token {
    my $self = shift;
    my $id   = shift;

    return $self->_post({
        endpoint   => 'tokens/disable',
        parameters => {
            token => $id,
        },
    });
}

sub enable_personal_access_token {
    my $self = shift;
    my $id   = shift;

    return $self->_post({
        endpoint   => 'tokens/enable',
        parameters => {
            token => $id,
        },
    });
}

sub search_tokens {
    my $self = shift;
    my $term = shift;

    return $self->_post({
        endpoint   => 'tokens/search',
        parameters => {
            term => $term,
        },
    });
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::Users

=head1 DESCRIPTION

=head2 USAGE

    use WebService::Mattermost;

    my $mm = WebService::Mattermost->new({
        authenticate => 1,
        username     => 'me@somewhere.com',
        password     => 'hunter2',
        base_url     => 'https://my.mattermost.server.com/api/v4/',
    });

    my $resource = $mm->api->users;

=head2 METHODS

=over 4

=item C<login()>

L<Authentication|https://api.mattermost.com/#tag/authentication>

Log into the Mattermost server using a username and password.

    my $response = $resource->login({
        username => 'USERNAME-HERE',
        password => 'PASSWORD-HERE',
    });

=item C<create()>

L<Create a user|https://api.mattermost.com/#tag/users%2Fpaths%2F~1users%2Fpost>

Create a new user on the server.

    my $response = $resource->create({
        # Required parameters:
        email    => '...',
        username => '...',
        password => '...',

        # Optional parameters:
        first_name   => '...',
        last_name    => '...',
        nickname     => '...',
        locale       => '...',
        props        => {
            # ...
        },
        notify_props => {
            # ...
        },
    });

=item C<list()>

L<Get users|https://api.mattermost.com/#tag/users%2Fpaths%2F~1users%2Fget>

    my $response = $resource->list({
        # Optional parameters:
        page           => 0,
        per_page       => 60,
        in_team        => 'TEAM-ID-HERE',
        not_in_team    => 'TEAM-ID-HERE',
        in_channel     => 'CHANNEL-ID-HERE',
        not_in_channel => 'CHANNEL-ID-HERE',
        without_team   => \1,
        sort           => 'STRING',
    });

=item C<list_by_ids()>

L<Get users by IDs|https://api.mattermost.com/#tag/users%2Fpaths%2F~1users~1ids%2Fpost>

Takes an ArrayRef of IDs as its only argument.

    my $users = $resource->list_by_ids([ qw(
        USER-ID-1
        USER-ID-2
        USER-ID-3
    ) ]);

=item C<list_by_usernames()>

L<Get by usernames|https://api.mattermost.com/#tag/users%2Fpaths%2F~1users~1usernames%2Fpost>

Takes an ArrayRef of usernames.

    my $users = $resource->list_by_usernames([ qw(
        USERNAME-1
        USERNAME-2
        USERNAME-3
    ) ]);

=item C<search()>

L<Search users|https://api.mattermost.com/#tag/users%2Fpaths%2F~1users~1search%2Fpost>

    my $response = $resource->search({
        # Required parameters:
        term => 'SEARCH-TERM-HERE',

        # Optional parameters:
        team_id           => 'TEAM-ID-HERE',
        not_in_team_id    => 'TEAM-ID-HERE',
        in_channel_id     => 'CHANNEL-ID-HERE',
        not_in_channel_id => 'CHANNEL-ID-HERE',
        allow_inactive    => \1, # or \0 - true/false
        without_team      => \1,
        sort              => 'STRING',
    });

=item C<autocomplete()>

L<Autocomplete users|https://api.mattermost.com/#tag/users%2Fpaths%2F~1users~1autocomplete%2Fget>

    my $response = $resource->autocomplete({
        # Required parameters:
        name => 'USERNAME-HERE',

        # Optional parameters:
        team_id    => 'TEAM-ID-HERE',
        channel_id => 'CHANNEL-ID-HERE',
    });

=item C<get_by_username()>

L<Get a user by username|https://api.mattermost.com/#tag/users%2Fpaths%2F~1users~1username~1%7Busername%7D%2Fget>

Get a user by their username (exact match only).

    my $response = $resource->get_by_username('mike');

=item C<reset_password_by_id()>

L<Reset password|https://api.mattermost.com/#tag/users%2Fpaths%2F~1users~1password~1reset%2Fpost>

Reset a user's password. Requires a recovery code.

    my $response = $resource->reset_password({
        new_password => 'hunter2',
        code         => 1234
    });

=item C<check_mfa_by_username()>

L<Check MFA|https://api.mattermost.com/#tag/users%2Fpaths%2F~1users~1mfa%2Fpost>

Check whether a user requires multi-factor auth by username or email.

    my $response = $resource->check_mfa_by_username('USERNAME-HERE');

=item C<send_password_reset_email()>

L<Send password reset email|https://api.mattermost.com/#tag/users%2Fpaths%2F~1users~1password~1reset~1send%2Fpost>

Send a password reset email.

    my $response = $resource->send_password_reset_email('me@somewhere.com');

=item C<get_by_email()>

L<Get a user by email|https://api.mattermost.com/#tag/users%2Fpaths%2F~1users~1email~1%7Bemail%7D%2Fget>

Get a user by email address.

    my $response = $resource->get_by_email('me@somewhere.com');

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

