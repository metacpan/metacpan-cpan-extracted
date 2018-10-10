package WebService::Mattermost::V4::API::Resource::License;

use Moo;

extends 'WebService::Mattermost::V4::API::Resource';

################################################################################

sub upload {
    my $self     = shift;
    my $filename = shift;

    return $self->_single_view_post({
        override_data_type => 'form',
        parameters         => {
            license => { file => $filename },
        },
        view               => 'Status',
    });
}

sub remove {
    my $self = shift;

    return $self->_single_view_delete({
        view => 'Response',
    });
}

sub client {
    my $self = shift;

    return $self->_single_view_get({
        endpoint => 'client',
        view     => 'Response',
    });
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::License

=head1 DESCRIPTION

=head2 USAGE

    use WebService::Mattermost;

    my $mm = WebService::Mattermost->new({
        authenticate => 1,
        username     => 'me@somewhere.com',
        password     => 'hunter2',
        base_url     => 'https://my.mattermost.server.com/api/v4/',
    });

    my $resource = $mm->api->license;

=head2 METHODS

=over 4

=item C<upload()>

L<Upload license file|https://api.mattermost.com/#tag/system%2Fpaths%2F~1license%2Fpost>

    my $response = $resource->upload('/path/to/license');

=item C<remove()>

L<Remove license file|https://api.mattermost.com/#tag/system%2Fpaths%2F~1license%2Fdelete>

    my $response = $resource->remove();

=item C<client()>

L<Get client license|https://api.mattermost.com/#tag/system%2Fpaths%2F~1license~1client%2Fget>

    my $response = $resource->client();

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

