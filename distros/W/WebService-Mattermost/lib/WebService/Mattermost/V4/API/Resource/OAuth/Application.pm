package WebService::Mattermost::V4::API::Resource::OAuth::Application;

use Moo;

extends 'WebService::Mattermost::V4::API::Resource';
with    'WebService::Mattermost::V4::API::Resource::Role::View::Application';

################################################################################

around [ qw(get update delete regenerate_secret get_info) ] => sub {
    my $orig = shift;
    my $self = shift;
    my $id   = shift;

    return $self->validate_id($orig, $id, @_);
};

sub get {
    my $self = shift;
    my $id   = shift;

    return $self->_single_view_get({
        endpoint => 'apps/%s',
        ids      => [ $id ],
    });
}

sub update {
    my $self = shift;
    my $id   = shift;
    my $args = shift;

    $args->{id} ||= $id;

    return $self->_single_view_put({
        endpoint    => 'apps/%s',
        ids         => [ $id ],
        parameters  => $args,
        required    => [ qw(id name description callback_urls homepage) ],
    });
}

sub delete {
    my $self = shift;
    my $id   = shift;

    return $self->_single_view_delete({
        endpoint => 'apps/%s',
        ids      => [ $id ],
        view     => 'Status',
    });
}

sub regenerate_secret {
    my $self = shift;
    my $id   = shift;

    return $self->_single_view_post({
        endpoint => 'apps/%s/regen_secret',
        ids      => [ $id ],
    });
}

sub get_info {
    my $self = shift;
    my $id   = shift;

    return $self->_single_view_get({
        endpoint => 'apps/%s/info',
        ids      => [ $id ],
    });
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::OAuth::Application

=head1 DESCRIPTION

=head2 USAGE

    use WebService::Mattermost;

    my $mm = WebService::Mattermost->new({
        authenticate => 1,
        username     => 'me@somewhere.com',
        password     => 'hunter2',
        base_url     => 'https://my.mattermost.server.com/api/v4/',
    });

    my $resource = $mm->api->application;

=head2 METHODS

=over 4

=item C<get()>

L<Get an OAuth app|https://api.mattermost.com/#tag/OAuth%2Fpaths%2F~1oauth~1apps~1%7Bapp_id%7D%2Fget>

    my $response = $resource->get('ID-HERE');

=item C<update()>

L<Update an OAuth app|https://api.mattermost.com/#tag/OAuth%2Fpaths%2F~1oauth~1apps~1%7Bapp_id%7D%2Fput>

    my $response = $resource->update('ID-HERE', {
        # Required parameters:
        id            => 'ID-HERE',
        name          => '...',
        description   => '...',
        callback_urls => [ '...' ],
        homepage      => '...',

        # Optional parameters:
        icon_url   => '...',
        is_trusted => \0, # or \1 for true
    });

=item C<delete()>

L<Delete an OAuth app|https://api.mattermost.com/#tag/OAuth%2Fpaths%2F~1oauth~1apps~1%7Bapp_id%7D%2Fdelete>

    my $response = $resource->delete('ID-HERE');

=item C<regenerate_secret()>

L<Regenerate OAuth app secret|https://api.mattermost.com/#tag/OAuth%2Fpaths%2F~1oauth~1apps~1%7Bapp_id%7D~1regen_secret%2Fpost>

    my $response = $resource->regenerate_secret('ID-HERE');

=item C<get_info()>

L<Get info on an OAuth app|https://api.mattermost.com/#tag/OAuth%2Fpaths%2F~1oauth~1apps~1%7Bapp_id%7D~1info%2Fget>

    my $response = $resource->get_info('ID-HERE');

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

