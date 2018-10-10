package WebService::Mattermost::V4::API::Resource::Brand;

use Moo;

extends 'WebService::Mattermost::V4::API::Resource';

################################################################################

sub current {
    my $self = shift;

    return $self->_get({ endpoint => 'image' });
}

sub upload {
    my $self     = shift;
    my $filename = shift;

    return $self->_post({
        endpoint           => 'image',
        override_data_type => 'form',
        parameters         => {
            image => { file => $filename },
        },
        view               => 'Status',
    });
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::Brand

=head1 DESCRIPTION

=head2 USAGE

    use WebService::Mattermost;

    my $mm = WebService::Mattermost->new({
        authenticate => 1,
        username     => 'email@address.com',
        password     => 'passwordhere',
        base_url     => 'https://my.mattermost.server.com/api/v4/',
    });

    my $brand = $mm->api->brand;

=head2 METHODS

=over 4

=item C<current()>

L<Get brand image|https://api.mattermost.com/#tag/brand%2Fpaths%2F~1brand~1image%2Fget>

Get the current brand image for your Mattermost server.

    my $response = $brand->current;

=item C<upload()>

L<Upload brand image|https://api.mattermost.com/#tag/brand%2Fpaths%2F~1brand~1image%2Fpost>

Set a new brand image for your Mattermost server.

    my $response = $brand->upload('/path/to/image.jpg');

=back

=head1 SEE ALSO

=over 4

=item L<Official "brand" API documentation|https://api.mattermost.com/#tag/brand>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

