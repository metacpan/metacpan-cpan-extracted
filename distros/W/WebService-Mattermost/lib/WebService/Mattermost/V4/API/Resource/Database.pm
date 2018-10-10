package WebService::Mattermost::V4::API::Resource::Database;

use Moo;

extends 'WebService::Mattermost::V4::API::Resource';

################################################################################

sub recycle {
    my $self = shift;

    return $self->_single_view_post({
        endpoint => 'recycle',
        view     => 'Status',
    });
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::Database

=head1 DESCRIPTION

=head2 USAGE

    use WebService::Mattermost;

    my $mm = WebService::Mattermost->new({
        authenticate => 1,
        username     => 'me@somewhere.com',
        password     => 'hunter2',
        base_url     => 'https://my.mattermost.server.com/api/v4/',
    });

    my $resource = $mm->api->database;

=head2 METHODS

=over 4

=item C<recycle()>

L<Recycle database connections|https://api.mattermost.com/#tag/system%2Fpaths%2F~1database~1recycle%2Fpost>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

