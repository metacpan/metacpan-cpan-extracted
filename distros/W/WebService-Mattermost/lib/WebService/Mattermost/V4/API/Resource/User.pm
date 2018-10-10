package WebService::Mattermost::V4::API::Resource::User;

use Moo;
use Types::Standard qw(HashRef Str);

extends 'WebService::Mattermost::V4::API::Resource';
with    qw(
    WebService::Mattermost::V4::API::Resource::Role::Single
    WebService::Mattermost::V4::API::Resource::Role::View::User
);

################################################################################

has available_user_roles => (is => 'ro', isa => HashRef, lazy => 1, builder => 1);

has role_system_admin => (is => 'ro', isa => Str, default => 'system_admin');
has role_system_user  => (is => 'ro', isa => Str, default => 'system_user');

################################################################################

around [ qw(
    get
    update
    teams
    patch

    update_roles
    update_active_status
    update_password
    update_authentication_method

    generate_mfa_secret
    update_mfa

    get_profile_image
    set_profile_image

    get_status
    set_status

    get_sessions
    revoke_session
    revoke_all_sessions

    get_preferences
    set_preferences
    delete_preferences
    list_preferences_by_category
    get_preference_by_category_and_name

    get_flagged_posts

    remove_reaction

    get_authorized_apps
    get_authorised_apps
) ] => sub {
    my $orig = shift;
    my $self = shift;
    my $id   = shift;

    return $self->validate_id($orig, $id, @_);
};

sub get {
    my $self = shift;
    my $id   = shift;

    return $self->_single_view_get({
        endpoint => '%s',
        ids      => [ $id ],
    });
}

sub update {
    my $self = shift;
    my $id   = shift;
    my $args = shift;

    return $self->_put({
        endpoint   => '%s',
        ids        => [ $id ],
        parameters => $args,
    });
}

sub teams {
    my $self = shift;
    my $id   = shift;

    return $self->_get({
        endpoint => '%s/teams',
        ids      => [ $id ],
        view     => 'Team',
    });
}

sub deactivate {
    my $self = shift;
    my $id   = shift;

    return $self->_delete({
        endpoint => '%s',
        ids      => [ $id ],
    });
}

sub patch {
    my $self = shift;
    my $id   = shift;
    my $args = shift;

    return $self->_put({
        endpoint   => '%s/patch',
        ids        => [ $id ],
        parameters => $args,
    });
}

sub update_roles {
    my $self  = shift;
    my $id    = shift;
    my $roles = shift; # ArrayRef

    foreach my $role (@{$roles}) {
        unless ($self->available_user_roles->{$role}) {
            my $err = sprintf('"%s" is not a valid role. Valid roles: %s',
                $role, join(', ', keys %{$self->available_user_roles}));

            return $self->_error_return($err);
        }
    }

    return $self->_put({
        endpoint   => '%s/roles',
        ids        => [ $id ],
        parameters => {
            roles => $roles,
        },
    });
}

sub generate_mfa_secret {
    my $self = shift;
    my $id   = shift;

    return $self->_post({
        endpoint => '%s/mfa/generate',
        ids      => [ $id ],
    });
}

sub update_mfa {
    my $self = shift;
    my $id   = shift;
    my $args = shift;

    return $self->_put({
        endpoint   => '%s/mfa',
        ids        => [ $id ],
        parameters => $args,
    });
}

sub get_profile_image {
    my $self = shift;
    my $id   = shift;

    return $self->_get({
        endpoint => '%s/image',
        ids      => [ $id ],
    });
}

sub set_profile_image {
    my $self     = shift;
    my $id       = shift;
    my $filename = shift;

    unless ($filename && -f $filename) {
        return $self->_error_return(sprintf('%s is not a valid file', $filename));
    }

    return $self->_post({
        endpoint           => '%s/image',
        ids                => [ $id ],
        override_data_type => 'form',
        parameters         => {
            image => { file => $filename },
        },
    });
}

sub update_active_status {
    my $self = shift;
    my $id   = shift;
    my $args = shift;

    return $self->_call({
        method     => $self->put,
        endpoint   => '%s/active',
        ids        => [ $id ],
        parameters => $args,
        required   => [ 'active' ],
    });
}

sub update_password {
    my $self = shift;
    my $id   = shift;
    my $args = shift;

    return $self->_put({
        endpoint   => '%s/password',
        ids        => [ $id ],
        parameters => $args,
    });
}

sub update_authentication_method {
    my $self = shift;
    my $id   = shift;
    my $args = shift;

    return $self->_put({
        endpoint  => '%s/auth',
        ids       => [ $id ],
        paramters => $args,
    });
}

sub get_status {
    my $self = shift;
    my $id   = shift;

    return $self->_single_view_get({
        endpoint => '%s/status',
        ids      => [ $id ],
        view     => 'User::Status',
    });
}

sub set_status {
    my $self   = shift;
    my $id     = shift;
    my $status = shift;

    # online, away, offline, dnd

    return $self->_single_view_put({
        endpoint   => '%s/status',
        ids        => [ $id ],
        parameters => {
            status => $status,
        },
        required   => [ 'status' ],
        view       => 'User::Status',
    });
}

sub get_sessions {
    my $self = shift;
    my $id   = shift;

    return $self->_get({
        endpoint => '%s/sessions',
        ids      => [ $id ],
        view     => 'User::Session',
    });
}

sub revoke_session {
    my $self       = shift;
    my $id         = shift;
    my $session_id = shift;

    return $self->_single_view_post({
        endpoint   => '%s/sessions/revoke',
        ids        => [ $id ],
        parameters => {
            session_id => $session_id,
        },
        required   => [ 'session_id' ],
        view       => 'Status',
    });
}

sub revoke_all_sessions {
    my $self = shift;
    my $id   = shift;

    return $self->_single_view_post({
        endpoint => '%s/sessions/revoke/all',
        view     => 'Status',
    });
}

sub get_preferences {
    my $self = shift;
    my $id   = shift;

    return $self->_get({
        endpoint => '%s/preferences',
        ids      => [ $id ],
        view     => 'User::Preference',
    });
}

sub set_preferences {
    my $self = shift;
    my $id   = shift;
    my $args = shift;

    unless (ref $args eq 'ARRAY') {
        return $self->error_return('An ArrayRef of preferences must be passed');
    }

    return $self->_single_view_put({
        endpoint   => '%s/preferences',
        ids        => [ $id ],
        parameters => $args,
        view       => 'Status',
    });
}

sub delete_preferences {
    my $self = shift;
    my $id   = shift;
    my $args = shift;

    unless (ref $args eq 'ARRAY') {
        return $self->error_return('An ArrayRef of preferences must be passed');
    }

    return $self->_single_view_post({
        endpoint   => '%s/preferences/delete',
        ids        => [ $id ],
        parameters => $args,
        view       => 'Status',
    });
}

sub list_preferences_by_category {
    my $self     = shift;
    my $id       = shift;
    my $category = shift;

    unless ($category) {
        return $self->error_return('A category is required');
    }

    return $self->_get({
        endpoint => '%s/preferences/%s',
        ids      => [ $id, $category ],
        view     => 'User::Category',
    });
}

sub get_preference_by_category_and_name {
    my $self     = shift;
    my $id       = shift;
    my $category = shift;
    my $name     = shift;

    unless ($category && $name) {
        return $self->error_return('A category and a name must be passed');
    }

    return $self->_single_view_get({
        endpoint => '%s/preferences/%s/name/%s',
        ids      => [ $id, $category, $name ],
        view     => 'User::Category',
    });
}

sub get_flagged_posts {
    my $self = shift;
    my $id   = shift;
    my $args = shift;

    return $self->_single_view_get({
        endpoint   => '%s/posts/flagged',
        ids        => [ $id ],
        parameters => $args,
        view       => 'Thread',
    });
}

sub remove_reaction {
    my $self       = shift;
    my $user_id    = shift;
    my $post_id    = shift;
    my $emoji_name = shift;

    unless ($post_id && $emoji_name) {
        return $self->error_return('A post ID and an emoji name are required');
    }

    return $self->_single_view_delete({
        endpoint => '%s/posts/%s/reactions/%s',
        ids      => [ $user_id, $post_id, $emoji_name ],
        view     => 'Status',
    });
}

sub get_authorized_apps { shift->get_authorised_apps(@_) }

sub get_authorised_apps {
    my $self = shift;
    my $id   = shift;
    my $args = shift;

    return $self->_get({
        endpoint   => '%s/oauth/apps/authorized',
        ids        => [ $id ],
        parameters => $args,
        view       => 'Application',
    });
}

################################################################################

sub _build_available_user_roles {
    my $self = shift;

    return {
        $self->role_system_admin => 1,
        $self->role_system_user  => 1,
    };
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::User

=head1 DESCRIPTION

API methods relating to a single user by ID.

=head2 USAGE

    use WebService::Mattermost;

    my $mm = WebService::Mattermost->new({
        authenticate => 1,
        username     => 'me@somewhere.com',
        password     => 'hunter2',
        base_url     => 'https://my.mattermost.server.com/api/v4/',
    });

    my $resource = $mm->api->user;

Optionally, you can set a global user ID for the resource and not pass the ID
to every method:

    $resource->id('USER-ID-HERE');

=head2 METHODS

All of the below methods can either be called as documented under each item, or
from a user result object:

    my $user = $resource->get('USER-ID-HERE')->item;

    # Calls method "teams"
    my $response = $user->call('teams');

    # Calls method "update"
    $response = $user->call('update', {
        # parameters
    });

=over 4

=item C<get()>

L<Get a user|https://api.mattermost.com/#tag/users%2Fpaths%2F~1users~1%7Buser_id%7D%2Fget>

Get a user by their ID.

    my $response = $resource->get('USER-ID-HERE');

=item C<update()>

L<Update a user|https://api.mattermost.com/#tag/users%2Fpaths%2F~1users~1%7Buser_id%7D%2Fput>

Update a user by their ID.

    my $response = $resource->update('USER-ID-HERE', {
        # Optional arguments
        email        => '...',
        username     => '...',
        first_name   => '...',
        last_name    => '...',
        nickname     => '...',
        locale       => '...',
        position     => '...',
        props        => {
            # ...
        },
        notify_props => {
            email         => \1,
            push          => \1,
            desktop       => \1,
            desktop_sound => \1,
            mention_keys  => \1,
            channel       => \1,
            first_name    => \1,
        },
    });

=item C<teams()>

L<Get a user's teams|https://api.mattermost.com/#tag/teams%2Fpaths%2F~1users~1%7Buser_id%7D~1teams%2Fget>

=item C<deactivate()>

L<Deactivate a user account|https://api.mattermost.com/#tag/users%2Fpaths%2F~1users~1%7Buser_id%7D%2Fdelete>

Set a user as inactive by ID.

    $response->deactivate('USER-ID-HERE');

=item C<patch()>

L<Patch a user|https://api.mattermost.com/#tag/users%2Fpaths%2F~1users~1%7Buser_id%7D~1patch%2Fput>

    my $response = $resource->patch('USER-ID-HERE', {
        # Optional parameters:
        email        => '...',
        username     => '...',
        first_name   => '...',
        last_name    => '...',
        nickname     => '...',
        locale       => '...',
        position     => '...',
        props        => {
            # ...
        },
        notify_props => {
            email         => \1,
            push          => \1,
            desktop       => \1,
            desktop_sound => \1,
            mention_keys  => \1,
            channel       => \1,
            first_name    => \1,
        },
    });

=item C<update_roles()>

L<Update a user's roles|https://api.mattermost.com/#tag/users%2Fpaths%2F~1users~1%7Buser_id%7D~1roles%2Fput>

Valid roles are C<system_user> and C<system_admin>.

    my $response = $resource->update_roles('USER-ID-HERE', [
        'ROLE-NAME-HERE',
        'ANOTHER-ROLE-HERE',
    ]);

=item C<generate_mfa_secret()>

L<Generate MFA secret|https://api.mattermost.com/#tag/users%2Fpaths%2F~1users~1%7Buser_id%7D~1mfa~1generate%2Fpost>

Returns a base64 encoded QR code image.

    my $response = $resource->generate_mfa_secret('USER-ID-HERE');

=item C<update_mfa()>

L<Update a user's MFA|https://api.mattermost.com/#tag/users%2Fpaths%2F~1users~1%7Buser_id%7D~1mfa%2Fput>

Set whether a user requires multi-factor auth. If the user currently has MFA
active, a code from the MFA client is required.

    my $response = $resource->update_mfa('ID-HERE', {
        activate => \1,   # or \0 for false
        code     => 1234, # required if MFA is already active
    });

=item C<get_profile_image()>

L<Get user's profile image|https://api.mattermost.com/#tag/users%2Fpaths%2F~1users~1%7Buser_id%7D~1image%2Fget>

Get a user's profile image. Warning: returns binary content.

    my $response = $resource->get_profile_image('ID-HERE');

    # $response->raw_content contains the image as binary

=item C<set_profile_image()>

L<Set user's profile image|https://api.mattermost.com/#tag/users%2Fpaths%2F~1users~1%7Buser_id%7D~1image%2Fpost>

Set a user's profile image.

    my $response = $resource->set_profile_image('ID-HERE', '/path/to/file.jpg');

=item C<update_active_status()>

L<Update user active status|https://api.mattermost.com/#tag/users%2Fpaths%2F~1users~1%7Buser_id%7D~1active%2Fput>

Set a user as active or inactive.

    $resource->update_active_status('ID-HERE', {
        active => \1, # \1 for true, \0 for false
    });

=item C<update_password()>

L<Update a user's password|https://api.mattermost.com/#tag/users%2Fpaths%2F~1users~1%7Buser_id%7D~1password%2Fput>

    my $response = $resource->update_password('ID-HERE', {
        old_password => '...',
        new_password => '...',
    });

=item C<update_authentication_method()>

L<Update a user's authentication method|https://api.mattermost.com/#tag/users%2Fpaths%2F~1users~1%7Buser_id%7D~1auth%2Fput>

    my $response = $resource->update_authentication_method('USER-ID-HERE', {
        # Optional parameters:
        auth_data    => '...',
        auth_service => '...',
        password     => '...',
    });

=item C<get_status()>

L<Get a user's status|https://api.mattermost.com/#tag/status%2Fpaths%2F~1users~1%7Buser_id%7D~1status%2Fget>

    my $response = $resource->get_status('USER-ID-HERE');

=item C<set_status()>

L<Update a user's status|https://api.mattermost.com/#tag/status%2Fpaths%2F~1users~1%7Buser_id%7D~1status%2Fput>

    my $response = $resource->set_status('USER-ID-HERE', 'STATUS-HERE');

Available statuses are "online", "away", "offline" and "dnd".

=item C<get_sessions()>

L<Get a user's sessions|https://api.mattermost.com/#tag/users%2Fpaths%2F~1users~1%7Buser_id%7D~1sessions%2Fget>

    my $response = $resource->get_sessions('USER-ID-HERE');

=item C<revoke_session()>

L<Revoke a user sesssion|https://api.mattermost.com/#tag/users%2Fpaths%2F~1users~1%7Buser_id%7D~1sessions~1revoke%2Fpost>

    my $response = $resource->revoke_session('USER-ID-HERE', 'SESSION-ID-HERE');

=item C<revoke_all_sessions()>

L<Revoke all active sessions for a user|https://api.mattermost.com/#tag/users%2Fpaths%2F~1users~1%7Buser_id%7D~1sessions~1revoke~1all%2Fpost>

    my $response = $resource->revoke_all_sessions('USER-ID-HERE');

=item C<get_preferences()>

L<Get the user's preferences|https://api.mattermost.com/#tag/preferences%2Fpaths%2F~1users~1%7Buser_id%7D~1preferences%2Fget>

    my $response = $resource->get_preferences('USER-ID-HERE');

=item C<set_preferences()>

L<Save the user's preferences|https://api.mattermost.com/#tag/preferences%2Fpaths%2F~1users~1%7Buser_id%7D~1preferences%2Fput>

    my $response = $resource->set_preferences('USER-ID-HERE', [
        { user_id => 'USER-ID-HERE', category => '...', name => '...', value => '...' },
        { user_id => 'USER-ID-HERE', category => '...', name => '...', value => '...' },
        { user_id => 'USER-ID-HERE', category => '...', name => '...', value => '...' },
    ]);

=item C<delete_preferences()>

L<Delete user's preferences|https://api.mattermost.com/#tag/preferences%2Fpaths%2F~1users~1%7Buser_id%7D~1preferences~1delete%2Fpost>

    my $response = $resource->delete_preferences('USER-ID-HERE', [
        { user_id => 'USER-ID-HERE', category => '...', name => '...', value => '...' },
        { user_id => 'USER-ID-HERE', category => '...', name => '...', value => '...' },
        { user_id => 'USER-ID-HERE', category => '...', name => '...', value => '...' },
    ]);

=item C<list_preferences_by_category()>

L<List a user's preferences by category|https://api.mattermost.com/#tag/preferences%2Fpaths%2F~1users~1%7Buser_id%7D~1preferences~1%7Bcategory%7D%2Fget>

    my $response = $resource->list_preferences_by_category('USER-ID-HERE', 'CATEGORY-HERE');

=item C<get_preference_by_category_and_name()>

L<Get a specific user preference|https://api.mattermost.com/#tag/preferences%2Fpaths%2F~1users~1%7Buser_id%7D~1preferences~1%7Bcategory%7D~1name~1%7Bpreference_name%7D%2Fget>

    my $response = $resource->get_preference_by_category_and_name(
        'USER-ID-HERE',
        'CATEGORY-HERE',
        'NAME-HERE',
    );

=item C<get_flagged_posts()>

L<Get a list of flagged posts|https://api.mattermost.com/#tag/posts%2Fpaths%2F~1users~1%7Buser_id%7D~1posts~1flagged%2Fget>

Retrieve a list of posts flagged by the user with the given ID.

    my $response = $resource->get_flagged_posts('USER-ID-HERE', {
        # Optional parameters
        team_id    => '...',
        channel_id => '...',
        page       => 0,
        per_page   => 60,
    });

=item C<remove_reaction()>

L<Remove a reaction from a user's post|https://api.mattermost.com/#tag/reactions%2Fpaths%2F~1users~1%7Buser_id%7D~1posts~1%7Bpost_id%7D~1reactions~1%7Bemoji_name%7D%2Fdelete>

    my $response = $resource->remove_reaction(
        'USER-ID-HERE',
        'POST-ID-HERE',
        'EMOJI-NAME-HERE',
    );

=item C<get_authorized_apps()>

Alias for C<get_authorised_apps()>.

=item C<get_authorised_apps()>

L<Get authorized OAuth apps|https://api.mattermost.com/#tag/OAuth%2Fpaths%2F~1users~1%7Buser_id%7D~1oauth~1apps~1authorized%2Fget>

    my $response = $resource->get_authorised_apps('USER-ID-HERE', {
        # Optional parameters:
        page     => 0,
        per_page => 60,
    });

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

