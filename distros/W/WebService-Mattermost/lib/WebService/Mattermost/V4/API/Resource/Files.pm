package WebService::Mattermost::V4::API::Resource::Files;

use Moo;

extends 'WebService::Mattermost::V4::API::Resource';

################################################################################

around [ qw(upload) ] => sub {
    my $orig = shift;
    my $self = shift;
    my $id   = shift;

    return $self->validate_id($orig, $id, @_);
};

sub upload {
    my $self       = shift;
    my $channel_id = shift;
    my $filename   = shift;

    return $self->_post({
        override_data_type => 'form',
        parameters         => {
            channel_id => $channel_id,
            files      => { file => $filename },
        },
    });
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::Files

=head1 DESCRIPTION

=head2 USAGE

    use WebService::Mattermost;

    my $mm = WebService::Mattermost->new({
        authenticate => 1,
        username     => 'me@somewhere.com',
        password     => 'hunter2',
        base_url     => 'https://my.mattermost.server.com/api/v4/',
    });

    my $resource = $mm->api->files;

=head2 METHODS

=over 4

=item C<upload()>

Upload a file to a channel.

    $resource->upload('CHANNEL_ID_HERE', '/path/to/filename.txt');

=back

=head1 SEE ALSO

=over 4

=item L<Official Files documentation|https://api.mattermost.com/#tag/files>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

