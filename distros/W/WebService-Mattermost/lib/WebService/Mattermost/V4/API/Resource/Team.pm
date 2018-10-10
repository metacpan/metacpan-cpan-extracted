package WebService::Mattermost::V4::API::Resource::Team;

use Moo;
use Types::Standard 'InstanceOf';

use WebService::Mattermost::V4::API::Resource::Team::Channels;
use WebService::Mattermost::Helper::Alias 'v4';

extends 'WebService::Mattermost::V4::API::Resource';
with    qw(
    WebService::Mattermost::V4::API::Resource::Role::Single
    WebService::Mattermost::V4::API::Resource::Role::View::Team
);

################################################################################

has channels => (is => 'ro', isa => InstanceOf[v4 'Team::Channels'], lazy => 1, builder => 1);

################################################################################

around [ qw(
    delete
    get
    patch
    update

    add_member
    add_members
    members
    members_by_ids
    invite_by_emails

    stats

    get_icon
    set_icon
    remove_icon

    set_scheme

    search_posts
) ] => sub {
    my $orig = shift;
    my $self = shift;
    my $id   = shift || $self->id;

    return $self->validate_id($orig, $id, @_);
};

around [ qw(get_by_name exists_by_name) ] => sub {
    my $orig = shift;
    my $self = shift;
    my $name = shift;

    unless ($name) {
        return $self->_error_return('The first parameter must be a name.');
    }

    return $self->$orig($name, @_);
};

around [ qw(get_member remove_member) ] => sub {
    my $orig    = shift;
    my $self    = shift;
    my $team_id = shift;
    my $user_id = shift;

    unless ($team_id && $user_id) {
        return $self->_error_return('The first parameter should be a team ID and the second a user ID.');
    }

    return $self->$orig($team_id, $user_id, @_);
};

sub get {
    my $self = shift;
    my $id   = shift;

    return $self->_single_view_get({
        endpoint => '%s',
        ids      => [ $id ],
    });
}

sub get_by_name {
    my $self = shift;
    my $name = shift;

    return $self->_single_view_get({
        endpoint => 'name/%s',
        ids      => [ $name ],
    });
}

sub update {
    my $self = shift;
    my $id   = shift;
    my $args = shift;

    return $self->_single_view_put({
        endpoint   => '%s',
        ids        => [ $id ],
        parameters => $args,
        required   => [ qw(
            display_name
            description
            company_name
            allowed_domains
            invite_id
            allow_open_invite
        ) ],
    });
}

sub delete {
    my $self = shift;
    my $id   = shift;

    return $self->_delete({
        endpoint => '%s',
        ids      => [ $id ],
        view     => 'Status',
    });
}

sub patch {
    my $self = shift;
    my $id   = shift;
    my $args = shift;

    return $self->_single_view_put({
        endpoint   => '%s/patch',
        parameters => $args,
        ids        => [ $id ],
    });
}

sub exists_by_name {
    my $self = shift;
    my $name = shift;

    return $self->_get({
        endpoint => 'name/%s/exists',
        ids      => [ $name ],
    });
}

sub members {
    my $self = shift;
    my $id   = shift;

    return $self->_get({
        endpoint => '%s/members',
        ids      => [ $id ],
        view     => 'TeamMember',
    });
}

sub members_by_ids {
    my $self     = shift;
    my $team_id  = shift;
    my $user_ids = shift;

    return $self->_get({
        endpoint   => '%s/members/ids',
        ids        => [ $team_id ],
        parameters => $user_ids,
        view       => 'TeamMember',
    });
}

sub add_member {
    my $self    = shift;
    my $team_id = shift;
    my $user_id = shift;

    return $self->_single_view_post({
        endpoint   => '%s/members',
        ids        => [ $team_id ],
        view       => 'TeamMember',
        parameters => {
            team_id => $team_id,
            user_id => $user_id,
        },
    });
}

sub add_members {
    my $self     = shift;
    my $team_id  = shift;
    my $users    = shift;

    return $self->_post({
        endpoint   => '%s/members/batch',
        ids        => [ $team_id ],
        view       => 'TeamMember',
        parameters => [
            map {
                {
                    user_id => $_->{id},
                    team_id => $team_id,
                    roles   => $_->{roles},
                }
            } grep {
                defined($_->{id}) && defined($_->{roles})
            } @{$users}
        ],
    });
}

sub get_member {
    my $self    = shift;
    my $team_id = shift;
    my $user_id = shift;

    unless ($user_id) {
        return $self->_error_return('The second parameter should be a user ID');
    }

    return $self->_single_view_get({
        endpoint => '%s/members/%s',
        ids      => [ $team_id, $user_id ],
        view     => 'TeamMember',
    });
}

sub remove_member {
    my $self    = shift;
    my $team_id = shift;
    my $user_id = shift;

    return $self->_single_view_delete({
        endpoint => '%s/members/%s',
        ids      => [ $team_id, $user_id ],
        view     => 'Status',
    });
}

sub stats {
    my $self = shift;
    my $id   = shift;

    return $self->_single_view_get({
        endpoint => '%s/stats',
        ids      => [ $id ],
        view     => 'TeamStats',
    });
}

sub get_icon {
    my $self = shift;
    my $id   = shift;

    return $self->_single_view_get({
        endpoint => '%s/image',
        ids      => [ $id ],
        view     => 'Icon',
    });
}

sub set_icon {
    my $self     = shift;
    my $id       = shift;
    my $filename = shift;

    return $self->_single_view_post({
        endpoint           => '%s/image',
        ids                => [ $id ],
        override_data_type => 'form',
        parameters         => {
            image => { file => $filename },
        },
    });
}

sub remove_icon {
    my $self = shift;
    my $id   = shift;

    return $self->_single_view_delete({
        endpoint => '%s/image',
        ids      => [ $id ],
        view     => 'Status',
    });
}

sub invite_by_emails {
    my $self   = shift;
    my $id     = shift;
    my $emails = shift;

    return $self->_single_view_post({
        endpoint   => '%s/invite/email',
        ids        => [ $id ],
        parameters => $emails,
        view       => 'Status',
    });
}

sub import_from_existing {
    my $self = shift;
    my $id   = shift;
    my $args = shift;

    my $filename = $args->{filename};

    unless ($args->{file}) {
        return $self->_error_return('A filename argument is required');
    }

    $args->{file} = { file => { file => $args->{filename} } };

    return $self->_single_view_post({
        endpoint           => '%s/import',
        ids                => [ $id ],
        override_data_type => 'form',
        parameters         => $args,
        required           => [ qw(file filesize importFrom) ],
        view               => 'Results',
    });
}

sub set_scheme {
    my $self   = shift;
    my $id     = shift;
    my $scheme = shift;

    return $self->_single_view_put({
        endpoint   => '%s/scheme',
        ids        => [ $id ],
        parameters => { scheme_id  => $scheme },
        required   => [ 'scheme_id' ],
        view       => 'Status',
    });
}

sub search_posts {
    my $self = shift;
    my $id   = shift;
    my $args = shift;

    $args->{is_or_search} ||= \0;

    return $self->_single_view_post({
        endpoint   => '%s/posts/search',
        ids        => [ $id ],
        parameters => $args,
        required   => [ qw(terms is_or_search) ],
        view       => 'Thread',
    });
}

################################################################################

sub _build_channels {
    my $self = shift;

    return $self->_new_related_resource('teams', 'Team::Channels');
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::Team

=head1 DESCRIPTION

API methods relating to a single team by ID or name.

=head2 USAGE

    use WebService::Mattermost;

    my $mm = WebService::Mattermost->new({
        authenticate => 1,
        username     => 'me@somewhere.com',
        password     => 'hunter2',
        base_url     => 'https://my.mattermost.server.com/api/v4/',
    });

    my $resource = $mm->api->team;

=head2 METHODS

=over 4

=item C<get()>

L<Get a team|https://api.mattermost.com/#tag/teams%2Fpaths%2F~1teams~1%7Bteam_id%7D%2Fget>

    my $response = $resource->get('TEAM-ID-HERE');

=item C<get_by_name()>

L<Get a team by name|https://api.mattermost.com/#tag/teams%2Fpaths%2F~1teams~1name~1%7Bname%7D%2Fget>

    my $response = $resource->get_by_name('TEAM-NAME-HERE');

=item C<update()>

L<Update a team|https://api.mattermost.com/#tag/teams%2Fpaths%2F~1teams~1%7Bteam_id%7D%2Fput>

    my $response = $resource->update('TEAM-ID-HERE', {
        # Required parameters:
        display_name    => '...',
        description     => '...',
        company_name    => '...',
        allowed_domains => '...',
        invite_id       => '...',
    });

=item C<delete()>

L<Delete a team|https://api.mattermost.com/#tag/teams%2Fpaths%2F~1teams~1%7Bteam_id%7D%2Fdelete>

    my $response = $resource->delete('TEAM-ID-HERE');

=item C<patch()>

L<Patch a team|https://api.mattermost.com/#tag/teams%2Fpaths%2F~1teams~1%7Bteam_id%7D~1patch%2Fput>

    my $response = $resource->patch('TEAM-ID-HERE', {
        # Optional parameters:
        display_name    => '...',
        description     => '...',
        company_name    => '...',
        allowed_domains => '...',
        invite_id       => '...',
    });

=item C<exists_by_name()>

L<Check if team exists|https://api.mattermost.com/#tag/teams%2Fpaths%2F~1teams~1name~1%7Bname%7D~1exists%2Fget>

    my $response = $resource->exists_by_name('TEAM-NAME-HERE');

=item C<members()>

L<Get team members|https://api.mattermost.com/#tag/teams%2Fpaths%2F~1teams~1%7Bteam_id%7D~1members%2Fget>

    my $response = $resource->members('TEAM-ID-HERE');

=item C<members_by_ids()>

L<Get team members by IDs|https://api.mattermost.com/#tag/teams%2Fpaths%2F~1teams~1%7Bteam_id%7D~1members~1ids%2Fpost>

    my $response = $resource->members_by_ids('TEAM-ID-HERE', [ qw(
        USER-ID-HERE
        USER-ID-HERE
        USER-ID-HERE
    ) ]);

=item C<add_member()>

L<Add user to team|https://api.mattermost.com/#tag/teams%2Fpaths%2F~1teams~1%7Bteam_id%7D~1members%2Fpost>

    my $response = $resource->add_member('TEAM-ID-HERE', 'USER-ID-HERE');

=item C<add_members()>

L<Add multiple users to team|https://api.mattermost.com/#tag/teams%2Fpaths%2F~1teams~1%7Bteam_id%7D~1members~1batch%2Fpost>

    my $response = $resource->add_members('TEAM-ID-HERE', [
        { user_id => 'USER-ID-HERE', roles => 'ROLES-HERE' },
        { user_id => 'USER-ID-HERE', roles => 'ROLES-HERE' },
        { user_id => 'USER-ID-HERE', roles => 'ROLES-HERE' },
    ]);

=item C<remove_member()>

L<Remove user from team|https://api.mattermost.com/#tag/teams%2Fpaths%2F~1teams~1%7Bteam_id%7D~1members~1%7Buser_id%7D%2Fdelete>

    my $response = $resource->remove_member('TEAM-ID-HERE', 'USER-ID-HERE');

=item C<stats()>

L<Get a team stats|https://api.mattermost.com/#tag/teams%2Fpaths%2F~1teams~1%7Bteam_id%7D~1stats%2Fget>

    my $response = $resource->stats('TEAM-ID-HERE');

=item C<get_icon()>

L<Get the team icon|https://api.mattermost.com/#tag/teams%2Fpaths%2F~1teams~1%7Bteam_id%7D~1image%2Fget>

    my $response = $resource->get_icon('TEAM-ID-HERE');

=item C<set_icon()>

L<Sets the team icon|https://api.mattermost.com/#tag/teams%2Fpaths%2F~1teams~1%7Bteam_id%7D~1image%2Fpost>

    my $response = $resource->set_icon('TEAM-ID-HERE', '/path/to/icon/here.png');

=item C<remove_icon()>

L<Remove the team icon|https://api.mattermost.com/#tag/teams%2Fpaths%2F~1teams~1%7Bteam_id%7D~1image%2Fdelete>

    my $response = $resource->remove_icon('TEAM-ID-HERE');

=item C<invite_by_emails()>

L<Invite users to the team by email|https://api.mattermost.com/#tag/teams%2Fpaths%2F~1teams~1%7Bteam_id%7D~1invite~1email%2Fpost>

    my $response = $resource->invite_by_emails('TEAM-ID-HERE', [
        EMAIL-HERE
        EMAIL-HERE
        EMAIL-HERE
    ]);

=item C<import_from_existing()>

L<Import a Team from other application|https://api.mattermost.com/#tag/teams%2Fpaths%2F~1teams~1%7Bteam_id%7D~1import%2Fpost>

    my $response = $resource->import_from_existing('TEAM-ID-HERE', {
        filename   => 'IMPORT-FILENAME',
        filesize   => 'filesize',
        importFrom => '...',
    });

=item C<search_posts()>

L<Search for team posts|https://api.mattermost.com/#tag/posts%2Fpaths%2F~1teams~1%7Bteam_id%7D~1posts~1search%2Fpost>

    my $response = $resource->search_posts('TEAM-ID-HERE', {
        # Required parameters:
        terms => '...',

        # Optional parameters
        is_or_search             => \1, # or \0 for false
        time_zone_offset         => 0,
        include_deleted_channels => \1, # or \0 for false
        page                     => 0,
        per_page                 => 60,
    });

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

