package WebService::Mattermost::V4::API::Object::Role::BelongingToChannel;

use Moo::Role;
use Types::Standard qw(InstanceOf Maybe Str);

use WebService::Mattermost::Helper::Alias 'view';

################################################################################

has channel_id => (is => 'ro', isa => Maybe[Str],                        lazy => 1, builder => 1);
has channel    => (is => 'ro', isa => Maybe[InstanceOf[view 'Channel']], lazy => 1, builder => 1);

################################################################################

sub _build_channel_id {
    my $self = shift;

    return $self->raw_data->{channel_id};
}

sub _build_channel {
    my $self = shift;

    return unless $self->channel_id;
    return $self->api->channel->get($self->channel_id)->item;
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::Role::BelongingToChannel

=head1 DESCRIPTION

Link a view object to its channel.

=head2 ATTRIBUTES

=over 4

=item C<channel_id>

The channel's ID.

=item C<channel>

Linked C<WebService::Mattermost::V4::API::Object::Channel> object.

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

