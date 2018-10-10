package WebService::Mattermost::V4::API::Object::Channel;

use Moo;
use Types::Standard qw(HashRef InstanceOf Int Maybe Str);

extends 'WebService::Mattermost::V4::API::Object';
with    qw(
    WebService::Mattermost::V4::API::Object::Role::APIMethods
    WebService::Mattermost::V4::API::Object::Role::Timestamps
    WebService::Mattermost::V4::API::Object::Role::BelongingToUser
    WebService::Mattermost::V4::API::Object::Role::BelongingToTeam
    WebService::Mattermost::V4::API::Object::Role::ID
    WebService::Mattermost::V4::API::Object::Role::Name
);

################################################################################

has [ qw(
    extra_updated_at
    last_post_at
) ] => (is => 'ro', isa => Maybe[InstanceOf['DateTime']], lazy => 1, builder => 1);

has [ qw(
    display_name
    header
    purpose
    type
) ] => (is => 'ro', isa => Maybe[Str], lazy => 1, builder => 1);

has [ qw(
    total_message_count
) ] => (is => 'ro', isa => Maybe[Int], lazy => 1, builder => 1);

################################################################################

sub BUILD {
    my $self = shift;

    $self->api_resource_name('channel');
    $self->set_available_api_methods([ qw(
        delete
        get
        patch
        pinned
        posts
        restore
        set_scheme
        stats
        toggle_private_status
        update
    ) ]);

    return 1;
}

################################################################################

sub _build_extra_updated_at {
    my $self = shift;

    return $self->_from_epoch($self->raw_data->{extra_updated_at});
}

sub _build_display_name {
    my $self = shift;

    return $self->raw_data->{display_name};
}

sub _build_header {
    my $self = shift;

    return $self->raw_data->{header};
}

sub _build_purpose {
    my $self = shift;

    return $self->raw_data->{purpose};
}

sub _build_type {
    my $self = shift;

    return $self->raw_data->{type} eq 'O' ? 'Public' : 'Private';
}

sub _build_total_message_count {
    my $self = shift;

    return $self->raw_data->{total_message_count};
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::Channel

=head1 DESCRIPTION

Details a Mattermost channel object.

=head2 METHODS

See matching methods in C<WebService::Mattermost::V4::API::Resource::Channel>
for full documentation.

ID parameters are not required:

    my $response = $mattermost->api->channel->get('ID-HERE')->item->delete();

Is the same as:

    my $response = $mattermost->api->channel->delete('ID-HERE');

=over 4

=item C<delete()>

=item C<patch()>

=item C<pinned()>

=item C<posts()>

=item C<restore()>

=item C<set_scheme()>

=item C<stats()>

=item C<toggle_private_status()>

=item C<update()>

=back

=head2 ATTRIBUTES

=over 4

=item C<extra_updated_at>

A DateTime object for when the channel was updated (extra).

=item C<last_post_at>

A DateTime object for when the channel was last posted to.

=item C<creator_id>

The ID of the user who created the channel.

=item C<display_name>

The channel's display name.

=item C<header>

The channel's topic

=item C<id>

The channel's ID.

=item C<name>

The channel's real name.

=item C<purpose>

A description of what the channel is for.

=item C<team_id>

The ID of the team the channel belongs to.

=item C<type>

The channel's access type (either "Public" or "Private", translated from "O" or
"P" respectively).

=item C<total_message_count>

The number of messages made in the channel.

=back

=head1 SEE ALSO

=over 4

=item C<WebService::Mattermost::V4::API::Resource::Channel>

=item C<WebService::Mattermost::V4::API::Object::Role::Timestamps>

=item C<WebService::Mattermost::V4::API::Object::Role::BelongingToUser>

=item C<WebService::Mattermost::V4::API::Object::Role::BelongingToTeam>

=item C<WebService::Mattermost::V4::API::Object::Role::ID>

=item C<WebService::Mattermost::V4::API::Object::Role::Name>

=item L<Channel documentation|https://api.mattermost.com/#tag/channels>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

