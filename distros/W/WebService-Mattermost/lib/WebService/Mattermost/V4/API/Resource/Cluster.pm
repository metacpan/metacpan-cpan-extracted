package WebService::Mattermost::V4::API::Resource::Cluster;

use Moo;

extends 'WebService::Mattermost::V4::API::Resource';

################################################################################

sub status {
    my $self = shift;

    return $self->_get({ endpoint => 'status' });
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::Cluster

=head1 DESCRIPTION

=head2 USAGE

    use WebService::Mattermost;

    my $mm = WebService::Mattermost->new({
        authenticate => 1,
        username     => 'email@address.com',
        password     => 'passwordhere',
        base_url     => 'https://my.mattermost.server.com/api/v4/',
    });

    my $cluster = $mm->api->cluster;

=head2 METHODS

=over 4

=item C<status()>

    my $response = $cluster->status;

=back

=head1 SEE ALSO

=over 4

=item L<https://api.mattermost.com/#tag/cluster>

Official "cluster" API documentation.

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

