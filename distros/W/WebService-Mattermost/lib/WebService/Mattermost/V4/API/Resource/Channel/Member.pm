package WebService::Mattermost::V4::API::Resource::Channel::Member;

use Moo;
use Types::Standard 'Str';

extends 'WebService::Mattermost::V4::API::Resource::Channel';
with    qw(
    WebService::Mattermost::V4::API::Resource::Role::View::Channel::Member
);

################################################################################

has channel_id => (is => 'rw', isa => Str);
has user_id    => (is => 'rw', isa => Str);

################################################################################

around [ qw(
    all
    get
    get_many
    remove
    set_notify_props
    set_roles
    set_scheme_roles
    set_viewed
) ] => sub {
    my $orig = shift;
    my $self = shift;

    my @args = (
        !$_[0] || ref $_[0] ? $self->channel_id : $_[0],
        !$_[1]              ? $self->user_id    : $_[1],
    );

    if (ref $_[-1]) {
        push @args, $_[-1];
    } else {
        push @args, ref $_[0] ? $_[0] : {};
    }

    if (scalar @args != 3) {
        return $self->error_return('Unexpected number of arguments provided');
    }

    return $self->$orig(@args);
};


sub add {
    my $self = shift;
    my $id   = shift;
    my $args = shift;

    return $self->_single_view_post({
        endpoint   => '%s/members',
        ids        => [ $id ],
        parameters => $args,
        required   => [ 'user_id' ],
    });
}

sub all {
    my $self = shift;
    my $id   = shift;

    return $self->_get({
        endpoint => '%s/members',
        ids      => [ $id ],
    });
}

sub get {
    my $self       = shift;
    my $channel_id = shift;
    my $user_id    = shift;

    return $self->_single_view_get({
        endpoint => '%s/members/%s',
        ids      => [ $channel_id, $user_id ],
    });
}

sub get_many {
    my $self       = shift;
    my $channel_id = shift;
    my $user_ids   = shift;

    unless (ref $user_ids eq 'ARRAY') {
        return $self->error_return('An ArrayRef of user IDs is required');
    }

    return $self->_post({
        endpoint   => '%s/members/ids',
        ids        => [ $channel_id ],
        parameters => $user_ids,
    });
}

sub remove {
    my $self       = shift;
    my $channel_id = shift;
    my $user_id    = shift;

    return $self->error_return('A user ID is required') unless $user_id;
    return $self->_single_view_delete({
        endpoint => '%s/members/%s',
        ids      => [ $channel_id, $user_id ],
        view     => 'Status',
    });
}

sub set_notify_props {
    my $self       = shift;
    my $channel_id = shift;
    my $user_id    = shift;
    my $args       = shift;

    return $self->_single_view_put({
        endpoint   => '%s/members/%s/notify_props',
        ids        => [ $channel_id, $user_id ],
        parameters => $args,
        view       => 'Status',
    });
}

sub set_roles {
    my $self       = shift;
    my $channel_id = shift;
    my $user_id    = shift;
    my $args       = shift;

    return $self->_single_view_put({
        endpoint   => '%s/members/%s/roles',
        ids        => [ $channel_id, $user_id ],
        parameters => $args,
        required   => [ 'roles' ],
        view       => 'Status',
    });
}

sub set_scheme_roles {
    my $self       = shift;
    my $channel_id = shift;
    my $user_id    = shift;
    my $args       = shift;

    return $self->_single_view_put({
        endpoint   => '%s/members/%s/schemeRoles',
        ids        => [ $channel_id, $user_id ],
        parameters => $args,
        required   => [ qw(scheme_admin scheme_user) ],
        view       => 'Status',
    });
}

sub set_viewed {
    my $self       = shift;
    my $channel_id = shift;
    my $user_id    = shift;
    my $args       = shift;

    $args->{channel_id} = $channel_id;

    return $self->_single_view_post({
        endpoint   => '%s/members/%s/view',
        ids        => [ $user_id, $channel_id ],
        parameters => $args,
        required   => [ qw(channel_id) ],
        view       => 'Status',
    });
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::Channel::Member

=head1 DESCRIPTION

Channel member related API calls.

=head2 USAGE

    my $mm = WebService::Mattermost->new({
        authenticate => 1,
        username     => 'me@somewhere.com',
        password     => 'hunter2',
        base_url     => 'https://my.mattermost.server.com/api/v4/',
    });

    my $resource = $mm->api->channel_member;

Optionally, you can set global channel and user IDs, and not pass those arguments
to every method:

    $resource->channel_id('CHANNEL-ID-HERE');
    $resource->user_id('USER-ID-HERE');

This would make the C<get()> call look like:

    my $response = $resource->get();

And the C<add()> one look like:

    my $response = $resource->add({
        user_id      => '...',
        post_root_id => '...',
    });

=head2 METHODS

=over 4

=item C<add()>

L<Add user to channel|https://api.mattermost.com/#tag/channels%2Fpaths%2F~1channels~1%7Bchannel_id%7D~1members%2Fpost>

    my $response = $resource->add('CHANNEL-ID-HERE', {
        # Required parameters:
        user_id => '...',

        # Optional parameters:
        post_root_id => '...',
    });

=item C<all()>

L<Get channel members|https://api.mattermost.com/#tag/channels%2Fpaths%2F~1channels~1%7Bchannel_id%7D~1members%2Fget>

    my $response = $resource->all('CHANNEL-ID-HERE');

=item C<get()>

L<Get channel member|https://api.mattermost.com/#tag/channels%2Fpaths%2F~1channels~1%7Bchannel_id%7D~1members~1%7Buser_id%7D%2Fget>

    my $response = $resource->get('CHANNEL-ID-HERE', 'USER-ID-HERE');

=item C<get_many()>

L<Get channel members by IDs|https://api.mattermost.com/#tag/channels%2Fpaths%2F~1channels~1%7Bchannel_id%7D~1members~1ids%2Fpost>

=item C<remove()>

L<Remove user from channel|https://api.mattermost.com/#tag/channels%2Fpaths%2F~1channels~1%7Bchannel_id%7D~1members~1%7Buser_id%7D%2Fdelete>

    my $response = $resource->remove('CHANNEL-ID-HERE', 'USER-ID-HERE');

=item C<set_notify_props()>

L<Update channel notifications|https://api.mattermost.com/#tag/channels%2Fpaths%2F~1channels~1%7Bchannel_id%7D~1members~1%7Buser_id%7D~1notify_props%2Fput>

    my $response = $resource->set_notify_props('CHANNEL-ID-HERE', 'USER-ID-HERE', {
        email       => \1, # or \0 for false
        push        => \1,
        desktop     => \1,
        mark_unread => \1,
    });

=item C<set_roles()>

L<Update channel roles|https://api.mattermost.com/#tag/channels%2Fpaths%2F~1channels~1%7Bchannel_id%7D~1members~1%7Buser_id%7D~1roles%2Fput>

    my $response = $resource->set_roles('CHANNEL-ID-HERE', 'USER-ID-HERE', {
        # Required parameters:
        roles => 'SPACE DELIMITED ROLES',
    });

=item C<set_scheme_roles()>

L<Update the scheme-derived roles of a channel member|https://api.mattermost.com/#tag/channels%2Fpaths%2F~1channels~1%7Bchannel_id%7D~1members~1%7Buser_id%7D~1schemeRoles%2Fput>

    my $response = $resource->set_scheme_roles('CHANNEL-ID-HERE', 'USER-ID-HERE', {
        # Required parameters:
        scheme_admin => \0, # false
        scheme_user  => \1, # or true
    });

=item C<set_viewed()>

L<View channel|https://api.mattermost.com/#tag/channels%2Fpaths%2F~1channels~1members~1%7Buser_id%7D~1view%2Fpost>

    my $response = $resource->set_viewed('CHANNEL-ID-HERE', 'USER-ID-HERE', {
        # Optional parameters:
        prev_channel_id => '...',
    });

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

