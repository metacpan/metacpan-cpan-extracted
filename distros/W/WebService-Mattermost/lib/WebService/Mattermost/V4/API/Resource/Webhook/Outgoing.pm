package WebService::Mattermost::V4::API::Resource::Webhook::Outgoing;

use Moo;

extends 'WebService::Mattermost::V4::API::Resource';

################################################################################

around [ qw(get_by_id update_by_id regenerate_token) ] => sub {
    my $orig = shift;
    my $self = shift;
    my $id   = shift;

    return $self->validate_id($orig, $id, @_);
};

sub create {
    my $self = shift;
    my $args = shift;

    return $self->_post({
        endpoint   => 'outgoing',
        parameters => $args,
        required   => [ 'channel_id' ],
    });
}

sub list {
    my $self = shift;
    my $args = shift;

    return $self->_get({
        endpoint   => 'outgoing',
        parameters => $args,
    });
}

sub get_by_id {
    my $self = shift;
    my $id   = shift;

    return $self->_get({
        endpoint => 'outgoing/%s',
        ids      => [ $id ],
    });
}

sub update_by_id {
    my $self = shift;
    my $id   = shift;
    my $args = shift;

    $args->{hook_id} = $id;

    return $self->_put({
        endpoint   => 'outgoing/%s',
        ids        => [ $id ],
        parameters => $args,
        required   => [ qw(hook_id channel_id display_name description) ],
    });
}

sub regenerate_token {
    my $self = shift;
    my $id   = shift;

    return $self->_post({
        endpoint => 'outgoing/%s/regen_token',
        ids      => [ $id ],
    });
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::Webhook::Outgoing

=head1 DESCRIPTION

=head2 USAGE

    use WebService::Mattermost;

    my $mm = WebService::Mattermost->new({
        authenticate => 1,
        username     => 'me@somewhere.com',
        password     => 'hunter2',
        base_url     => 'https://my.mattermost.server.com/api/v4/',
    });

    my $resource = $mm->api->webhooks->outgoing;

=head2 METHODS

=over 4

=item C<create()>

L<Create an outgoing webhook|https://api.mattermost.com/#tag/webhooks%2Fpaths%2F~1hooks~1outgoing%2Fpost>

    my $response = $resource->create({
        # Required parameters:
        channel_id => 'CHANNEL-ID-HERE',

        # Optional parameters:
        display_name => '...',
        description  => '...',
        username     => '...',
        icon_url     => '...',
    });

=item C<list()>

L<List outgoing webhooks|https://api.mattermost.com/#tag/webhooks%2Fpaths%2F~1hooks~1outgoing%2Fget>

    my $response = $resource->list({
        # Optional parameters:
        page     => 0,
        per_page => 60,
        team_id  => 'TEAM-ID-HERE',
    });

=item C<get_by_id()>

L<Get an outgoing webhook|https://api.mattermost.com/#tag/webhooks%2Fpaths%2F~1hooks~1outgoing~1%7Bhook_id%7D%2Fget>

    my $response = $resource->get_by_id('WEBHOOK-ID-HERE');

=item C<update_by_id()>

L<Update an outgoing webhook|https://api.mattermost.com/#tag/webhooks%2Fpaths%2F~1hooks~1outgoing~1%7Bhook_id%7D%2Fput>

    my $response = $resource->update_by_id('WEBHOOK-ID-HERE', {
        # Required parameters:
        channel_id   => 'CHANNEL-ID-HERE',
        display_name => '...',
        description  => '...',

        # Optional parameters:
        username => '...',
        icon_url => '...',
    });

=item C<regenerate_token()>

L<Regenerate the token for the outgoing webhook|https://api.mattermost.com/#tag/webhooks%2Fpaths%2F~1hooks~1outgoing~1%7Bhook_id%7D~1regen_token%2Fpost>

    my $response = $resource->regenerate_token('WEBHOOK-ID-HERE');

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

