package WebService::Mattermost::V4::API::Resource::Channel;

use Moo;

extends 'WebService::Mattermost::V4::API::Resource';
with    qw(
    WebService::Mattermost::V4::API::Resource::Role::Single
    WebService::Mattermost::V4::API::Resource::Role::View::Channel
);

################################################################################

around [ qw(
    delete
    get
    patch
    pinned
    posts
    restore
    set_scheme
    stats
    toggle_private_status
    update
) ] => sub {
    my $orig = shift;
    my $self = shift;
    my $id   = shift;

    my @args = ($orig);

    if ($id) {
        push @args, $id;
    } elsif ($self->id) {
        push @args, $self->id;
    } else {
        push @args, '';
    }

    push @args, @_;

    return $self->validate_id(@args);
};

sub get {
    my $self = shift;
    my $id   = shift;

    return $self->_single_view_get({
        endpoint => '%s',
        ids      => [ $id ],
    });
}

sub update {
    my $self = shift;
    my $id   = shift;
    my $args = shift;

    $args->{id} = $id;

    return $self->_single_view_put({
        endpoint   => '%s',
        ids        => [ $id ],
        parameters => $args,
    });
}

sub delete {
    my $self = shift;
    my $id   = shift;

    return $self->_single_view_delete({
        endpoint => '%s',
        ids      => [ $id ],
        view     => 'Status',
    });
}

sub patch {
    my $self = shift;
    my $id   = shift;
    my $args = shift;

    return $self->_single_view_put({
        endpoint   => '%s/patch',
        ids        => [ $id ],
        parameters => $args,
    });
}

sub toggle_private_status {
    my $self = shift;
    my $id   = shift;

    return $self->_single_view_post({
        endpoint => '%s/convert',
        ids      => [ $id ],
    });
}

sub restore {
    my $self = shift;
    my $id   = shift;

    return $self->_single_view_post({
        endpoint => '%s/restore',
        ids      => [ $id ],
    });
}

sub stats {
    my $self = shift;
    my $id   = shift;

    return $self->_single_view_get({
        endpoint => '%s/stats',
        ids      => [ $id ],
    });
}

sub pinned {
    my $self = shift;
    my $id   = shift;

    # TODO: convert to ordered view of Posts when the Posts integration is done

    return $self->_single_view_get({
        endpoint => '%s/pinned',
        ids      => [ $id ],
        view     => '',
    });
}

sub set_scheme {
    my $self = shift;
    my $id   = shift;
    my $args = shift;

    return $self->_single_view_put({
        endpoint   => '%s/scheme',
        ids        => [ $id ],
        parameters => $args,
        required   => [ 'scheme_id' ],
        view       => 'Status',
    });
}

sub posts {
    my $self = shift;
    my $id   = shift;
    my $args = shift;

    return $self->_single_view_get({
        endpoint   => '%s/posts',
        ids        => [ $id ],
        parameters => $args,
        view       => 'Thread',
    });
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::Channel

=head1 DESCRIPTION

=head2 USAGE

    my $mm = WebService::Mattermost->new({
        authenticate => 1,
        username     => 'me@somewhere.com',
        password     => 'hunter2',
        base_url     => 'https://my.mattermost.server.com/api/v4/',
    });

    my $resource = $mm->api->channel;

Optionally, you can set a global channel ID and not pass that argument to
every method:

    $resource->id('CHANNEL-ID-HERE');

This would make the C<get()> call look like:

    my $response = $resource->get();

=head2 METHODS

=over 4

=item C<get()>

L<Get a channel|https://api.mattermost.com/#tag/channels%2Fpaths%2F~1channels~1%7Bchannel_id%7D%2Fget>

    my $response = $resource->get('CHANNEL-ID-HERE');

=item C<update()>

L<Update a channel|https://api.mattermost.com/#tag/channels%2Fpaths%2F~1channels~1%7Bchannel_id%7D%2Fput>

    my $response = $resource->update('CHANNEL-ID-HERE', {
        # Optional parameters
        name         => '...',
        display_name => '...',
        purpose      => '...',
        header       => '...',
        type         => '...',
    });

=item C<delete()>

L<Delete a channel|https://api.mattermost.com/#tag/channels%2Fpaths%2F~1channels~1%7Bchannel_id%7D%2Fdelete>

    my $response = $resource->delete('CHANNEL-ID-HERE');

=item C<patch()>

L<Patch a channel|https://api.mattermost.com/#tag/channels%2Fpaths%2F~1channels~1%7Bchannel_id%7D~1patch%2Fput>

    my $response = $resource->patch('CHANNEL-ID-HERE', {
        # Optional parameters
        name         => '...',
        display_name => '...',
        purpose      => '...',
        header       => '...',
    });

=item C<toggle_private_status()>

L<Convert a channel from public to private|https://api.mattermost.com/#tag/channels%2Fpaths%2F~1channels~1%7Bchannel_id%7D~1convert%2Fpost>

    my $response = $resource->toggle_private_status('CHANNEL-ID-HERE');

=item C<restore()>

L<Restore a channel|https://api.mattermost.com/#tag/channels%2Fpaths%2F~1channels~1%7Bchannel_id%7D~1restore%2Fpost>

    my $response = $resource->restore('CHANNEL-ID-HERE');

=item C<stats()>

L<Get channel statistics|https://api.mattermost.com/#tag/channels%2Fpaths%2F~1channels~1%7Bchannel_id%7D~1stats%2Fget>

    my $response = $resource->stats('CHANNEL-ID-HERE');

=item C<pinned()>

L<Get a channel's pinned posts|https://api.mattermost.com/#tag/channels%2Fpaths%2F~1channels~1%7Bchannel_id%7D~1pinned%2Fget>

    my $response = $resource->pinned('CHANNEL-ID-HERE');

=item C<set_scheme()>

L<Set a channel's scheme|https://api.mattermost.com/#tag/channels%2Fpaths%2F~1channels~1%7Bchannel_id%7D~1scheme%2Fput>

    my $response = $resource->set_scheme('CHANNEL-ID-HERE', {
        # Required parameters:
        scheme_id => '...',
    });

=item C<posts()>

L<Get posts for a channel|https://api.mattermost.com/#tag/posts%2Fpaths%2F~1channels~1%7Bchannel_id%7D~1posts%2Fget>

    my $response = $resource->posts('CHANNEL-ID-HERE', {
        # Optional parameters:
        page     => 0,
        per_page => 60,
        since    => 'UNIX-TIMESTAMP', # milliseconds
        before   => 'POST-ID-HERE',
        after    => 'POST-ID-HERE',
    });

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

