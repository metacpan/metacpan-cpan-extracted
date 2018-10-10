package WebService::Mattermost::V4::API::Resource::OAuth;

use Moo;

extends 'WebService::Mattermost::V4::API::Resource';
with    'WebService::Mattermost::V4::API::Resource::Role::View::Application';

################################################################################

sub register_app {
    my $self = shift;
    my $args = shift;

    return $self->_single_view_post({
        endpoint => 'apps',
        parameters => $args,
        required => [ qw(name description callback_urls homepage) ],
    });
}

sub get_apps {
    my $self = shift;
    my $args = shift;

    return $self->_get({
        endpoint   => 'apps',
        parameters => $args,
    });
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::OAuth

=head1 DESCRIPTION

=head2 USAGE

    use WebService::Mattermost;

    my $mm = WebService::Mattermost->new({
        authenticate => 1,
        username     => 'me@somewhere.com',
        password     => 'hunter2',
        base_url     => 'https://my.mattermost.server.com/api/v4/',
    });

    my $resource = $mm->api->oauth;

=head2 METHODS

=over 4

=item C<register_app()>

L<Register OAuth app|https://api.mattermost.com/#tag/OAuth%2Fpaths%2F~1oauth~1apps%2Fpost>

    my $response = $resource->register_app({
        # Required parameters:
        name          => '...',
        description   => '...',
        callback_urls => [ '...' ],
        homepage      => '...',

        # Optional parameters:
        icon_url   => '...',
        is_trusted => \0, # or \1 for true
    });

=item C<get_apps()>

L<Get OAuth apps|https://api.mattermost.com/#tag/OAuth%2Fpaths%2F~1oauth~1apps%2Fget>

    my $response = $resource->get_apps({
        # Optional parameters:
        page     => 0,
        per_page => 60,
    });

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

