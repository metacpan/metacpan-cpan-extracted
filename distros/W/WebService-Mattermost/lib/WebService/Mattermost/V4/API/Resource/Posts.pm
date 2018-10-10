package WebService::Mattermost::V4::API::Resource::Posts;

use Moo;

extends 'WebService::Mattermost::V4::API::Resource';
with    'WebService::Mattermost::V4::API::Resource::Role::View::Post';

################################################################################

sub create {
    my $self = shift;
    my $args = shift;

    $args->{message} = $self->_stringify_message($args->{message});

    return $self->_post({
        parameters => $args,
        required   => [ qw(channel_id message) ],
    });
}

sub create_ephemeral {
    my $self = shift;
    my $args = shift;

    unless ($self->_validate_minimum_post_args($args->{post})) {
        return $self->error_return('The "post" argument must contain message and channel_id keys');
    }

    $args->{post}->{message} = $self->_stringify_message($args->{post}->{message});

    return $self->_post({
        endpoint   => 'ephemeral',
        parameters => $args,
        required   => [ qw(user_id post) ],
    });
}

################################################################################

sub _stringify_message {
    my $self    = shift;
    my $message = shift;

    # This catch is in place to ensure a message of 1 or 0 are not interpreted
    # as a boolean value, and are instead sent as a string
    $message .= '' if $message && $message =~ /^\d+$/;

    return $message;
}

sub _validate_minimum_post_args {
    my $self = shift;
    my $post = shift;

    return ref $post
        && ref $post eq 'HASH'
        && $post->{channel_id}
        && $post->{message};
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::Posts

=head1 DESCRIPTION

=head2 USAGE

    use WebService::Mattermost;

    my $mm = WebService::Mattermost->new({
        authenticate => 1,
        username     => 'email@address.com',
        password     => 'passwordhere',
        base_url     => 'https://my.mattermost.server.com/api/v4/',
    });

    my $resource = $mm->api->posts;

=head2 METHODS

=over 4

=item C<create()>

L<Create a post|https://api.mattermost.com/#tag/posts%2Fpaths%2F~1posts%2Fpost>

    my $response = $resource->create({
        # Required parameters:
        message    => '...',
        channel_id => 'CHANNEL-ID-HERE',

        # Optional parameters:
        root_id  => 'PARENT-POST-ID-HERE',
        file_ids => [ '...' ],
        props    => {},
    });

=item C<create_ephemeral()>

L<Create a ephemeral post|https://api.mattermost.com/#tag/posts%2Fpaths%2F~1posts~1ephemeral%2Fpost>

    my $response = $resource->create_ephemeral({
        # Required parameters:
        user_id => 'USER-ID-HERE',
        post    => {
            channel_id => '...',
            message    => '...',
        },
    });

=back

=head1 SEE ALSO

=over 4

=item L<https://api.mattermost.com/#tag/posts>

Official "posts" API documentation.

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

