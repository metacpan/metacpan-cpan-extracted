package WebService::Mattermost::V4::API::Resource::Webhook;

use Moo;
use Types::Standard 'InstanceOf';

use WebService::Mattermost::Helper::Alias 'v4';
use WebService::Mattermost::V4::API::Resource::Webhook::Incoming;
use WebService::Mattermost::V4::API::Resource::Webhook::Outgoing;

extends 'WebService::Mattermost::V4::API::Resource';

################################################################################

has incoming => (is => 'ro', isa => InstanceOf[v4 'Webhook::Incoming'], lazy => 1, builder => 1);
has outgoing => (is => 'ro', isa => InstanceOf[v4 'Webhook::Incoming'], lazy => 1, builder => 1);

################################################################################

sub _build_incoming {
    my $self = shift;

    return $self->_new_related_resource('webhooks', 'Webhook::Incoming');
}

sub _build_outgoing {
    my $self = shift;

    return $self->_new_related_resource('webhooks', 'Webhook::Outgoing');
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::Webhook

=head1 DESCRIPTION

=head2 USAGE

    use WebService::Mattermost;

    my $mm = WebService::Mattermost->new({
        authenticate => 1,
        username     => 'me@somewhere.com',
        password     => 'hunter2',
        base_url     => 'https://my.mattermost.server.com/api/v4/',
    });

    my $resource = $mm->api->webhooks;

=head2 ATTRIBUTES

=over 4

=item C<incoming>

Contains methods for incoming webhooks. See
C<WebService::Mattermost::V4::API::Resource::Webhook::Incoming>.

    my $incoming = $resource->incoming;

=item C<outgoing>

Contains methods for outgoing webhooks. See
C<WebService::Mattermost::V4::API::Resource::Webhook::Outgoing>.

    my $outgoing = $resource->outgoing;

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

