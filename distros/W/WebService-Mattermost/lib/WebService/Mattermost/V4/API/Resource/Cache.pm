package WebService::Mattermost::V4::API::Resource::Cache;

use Moo;

extends 'WebService::Mattermost::V4::API::Resource';

################################################################################

sub invalidate {
    my $self = shift;

    return $self->_single_view_post({
        endpoint => 'invalidate',
        view     => 'Status',
    });
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::Cache

=head1 DESCRIPTION

=head2 USAGE

    use WebService::Mattermost;

    my $mm = WebService::Mattermost->new({
        authenticate => 1,
        username     => 'me@somewhere.com',
        password     => 'hunter2',
        base_url     => 'https://my.mattermost.server.com/api/v4/',
    });

    my $resource = $mm->api->cache;

=head2 METHODS

=over 4

=item C<invalidate()>

L<Invalidate all the caches|https://api.mattermost.com/#tag/system%2Fpaths%2F~1caches~1invalidate%2Fpost>

    my $response = $resource->invalidate();

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

