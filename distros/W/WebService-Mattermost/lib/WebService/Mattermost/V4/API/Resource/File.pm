package WebService::Mattermost::V4::API::Resource::File;

use Moo;

extends 'WebService::Mattermost::V4::API::Resource';

################################################################################

sub get {
    my $self    = shift;
    my $file_id = shift;

    return $self->_get({
        endpoint => '%s',
        ids      => [ $file_id ],
        view     => 'Binary',
    }); 
}

sub get_thumbnail {
    my $self    = shift;
    my $file_id = shift;

    return $self->_get({
        endpoint => '%s/thumbnail',
        ids      => [ $file_id ],
    }); 
}

sub get_preview {
    my $self    = shift;
    my $file_id = shift;

    return $self->_get({
        endpoint => '%s/preview',
        ids      => [ $file_id ],
    }); 
}

sub get_link {
    my $self    = shift;
    my $file_id = shift;

    return $self->_get({
        endpoint => '%s/link',
        ids      => [ $file_id ],
    }); 
}

sub get_metadata {
    my $self    = shift;
    my $file_id = shift;

    return $self->_get({
        endpoint => '%s/info',
        ids      => [ $file_id ],
    });
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::File

=head1 DESCRIPTION

=head2 USAGE

    use WebService::Mattermost;

    my $mm = WebService::Mattermost->new({
        authenticate => 1,
        username     => 'me@somewhere.com',
        password     => 'hunter2',
        base_url     => 'https://my.mattermost.server.com/api/v4/',
    });

    my $resource = $mm->api->file;

=head2 METHODS

=over 4

=item C<get()>

Get basic information about a file.

    $resource->get('FILE_ID_HERE');

=item C<get_thumbnail()>

Get a file's thumbnail

    $resource->get_thumbnail('FILE_ID_HERE');

=item C<get_preview()>

Get a file's preview.

    $resource->get_preview('FILE_ID_HERE');

=item C<get_link()>

Get a public link to a file.

    $resource->get_link('FILE_ID_HERE');

=item C<get_metadata()>

Get information about a file.

    $resource->get_metadata('FILE_ID_HERE');

=back

=head1 SEE ALSO

=over 4

=item L<Official Files documentation|https://api.mattermost.com/#tag/files>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

