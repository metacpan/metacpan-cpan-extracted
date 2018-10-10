package WebService::Mattermost::V4::API::Resource::ElasticSearch;

use Moo;

extends 'WebService::Mattermost::V4::API::Resource';

################################################################################

sub test {
    my $self = shift;

    return $self->_post({
        endpoint => 'test',
        view     => 'Status',
    });
}

sub purge_indexes {
    my $self = shift;

    return $self->_post({
        endpoint => 'purge',
        view     => 'Status',
    });
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::ElasticSearch

=head1 DESCRIPTION

=head2 USAGE

    use WebService::Mattermost;

    my $mm = WebService::Mattermost->new({
        authenticate => 1,
        username     => 'email@address.com',
        password     => 'passwordhere',
        base_url     => 'https://my.mattermost.server.com/api/v4/',
    });

    my $elasticsearch = $mm->api->elasticsearch;

=head2 METHODS

=over 4

=item C<test()>

    my $response = $elasticsearch->test;

=item C<purge_indexes()>

    my $response = $elasticsearch->purge_indexes;

=back

=head1 SEE ALSO

=over 4

=item L<https://api.mattermost.com/#tag/elasticsearch>

Official "ElasticSearch" API documentation.

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

