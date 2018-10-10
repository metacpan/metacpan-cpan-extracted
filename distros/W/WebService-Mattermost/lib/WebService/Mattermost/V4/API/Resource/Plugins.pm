package WebService::Mattermost::V4::API::Resource::Plugins;

use Moo;

extends 'WebService::Mattermost::V4::API::Resource';
with    'WebService::Mattermost::V4::API::Resource::Role::View::Plugins';

################################################################################

sub upload {
    my $self     = shift;
    my $filename = shift;

    return $self->_single_view_post({
        required           => [ qw(plugin) ],
        override_data_type => 'form',
        parameters         => {
            plugin => { file => $filename },
        },
        view               => 'Status',
    });
}

sub all {
    my $self = shift;

    return $self->_get();
}

sub all_webapp {
    my $self = shift;

    return $self->_get({ endpoint => 'webapp' });
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::Plugins

=head1 DESCRIPTION

=head2 USAGE

    use WebService::Mattermost;

    my $mm = WebService::Mattermost->new({
        authenticate => 1,
        username     => 'me@somewhere.com',
        password     => 'hunter2',
        base_url     => 'https://my.mattermost.server.com/api/v4/',
    });

    my $resource = $mm->api->plugins;

=head2 METHODS

=over 4

=item C<upload()>

L<Upload plugin|https://api.mattermost.com/#tag/plugins%2Fpaths%2F~1plugins%2Fpost>

    my $response = $resource->upload('/path/to/plugin.tar.gz');

=item C<all()>

L<Get plugins|https://api.mattermost.com/#tag/plugins%2Fpaths%2F~1plugins%2Fget>

    my $response = $resource->all();

=item C<webapp()>

L<Get webapp plugins|https://api.mattermost.com/#tag/plugins%2Fpaths%2F~1plugins~1webapp%2Fget>

    my $response = $resource->all_webapp();

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

