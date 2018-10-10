package WebService::Mattermost::V4::API::Resource::WebRTC;

use Moo;

extends 'WebService::Mattermost::V4::API::Resource';

################################################################################

sub get_token {
    my $self = shift;

    return $self->_single_view_get({
        endpoint => 'token',
        view     => 'WebRTCToken',
    });
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::WebRTC

=head1 DESCRIPTION

=head2 USAGE

    use WebService::Mattermost;

    my $mm = WebService::Mattermost->new({
        authenticate => 1,
        username     => 'me@somewhere.com',
        password     => 'hunter2',
        base_url     => 'https://my.mattermost.server.com/api/v4/',
    });

    my $resource = $mm->api->webrtc;

=head2 METHODS

=over 4

=item C<get_token()>

L<Get WebRTC token|https://api.mattermost.com/#tag/system%2Fpaths%2F~1webrtc~1token%2Fget>

    my $response = $resource->get_token();

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

