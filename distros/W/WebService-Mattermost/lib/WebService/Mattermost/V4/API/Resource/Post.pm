package WebService::Mattermost::V4::API::Resource::Post;

use Moo;

extends 'WebService::Mattermost::V4::API::Resource';
with    'WebService::Mattermost::V4::API::Resource::Role::View::Post';

################################################################################

around [ qw(
    get
    delete
    update
    patch

    thread
    files

    pin
    unpin

    reactions

    perform_action
) ] => sub {
    my $orig = shift;
    my $self = shift;
    my $id   = shift;

    return $self->validate_id($orig, $id, @_);
};

sub get {
    my $self = shift;
    my $id   = shift;

    return $self->_single_view_get({
        endpoint => '%s',
        ids      => [ $id ],
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

sub update {
    my $self = shift;
    my $id   = shift;
    my $args = shift;

    return $self->_single_view_put({
        endpoint   => '%s',
        ids        => [ $id ],
        parameters => $args,
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

sub thread {
    my $self = shift;
    my $id   = shift;

    return $self->_single_view_get({
        endpoint => '%s/thread',
        ids      => [ $id ],
        view     => 'Thread',
    });
}

sub files {
    my $self = shift;
    my $id   = shift;

    return $self->_get({
        endpoint => '%s/files/info',
        ids      => [ $id ],
        view     => 'File',
    });
}

sub pin {
    my $self = shift;
    my $id   = shift;

    return $self->_single_view_post({
        endpoint => '%s/pin',
        ids      => [ $id ],
        view     => 'Status',
    });
}

sub unpin {
    my $self = shift;
    my $id   = shift;

    return $self->_single_view_post({
        endpoint => '%s/unpin',
        ids      => [ $id ],
        view     => 'Status',
    });
}

sub reactions {
    my $self = shift;
    my $id   = shift;

    return $self->_get({
        endpoint => '%s/reactions',
        ids      => [ $id ],
        view     => 'Reaction',
    });
}

sub perform_action {
    my $self      = shift;
    my $post_id   = shift;
    my $action_id = shift;

    unless ($action_id) {
        return $self->error_return('An action ID is required');
    }

    return $self->_single_view_post({
        endpoint => '%s/actions/%s',
        ids      => [ $post_id, $action_id ],
        view     => 'Status',
    });
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::Post

=head1 DESCRIPTION

=head2 USAGE

    use WebService::Mattermost;

    my $mm = WebService::Mattermost->new({
        authenticate => 1,
        username     => 'email@address.com',
        password     => 'passwordhere',
        base_url     => 'https://my.mattermost.server.com/api/v4/',
    });

    my $resource = $mm->api->post;

=head2 METHODS

=over 4

=item C<get()>

L<Get a post|https://api.mattermost.com/#tag/posts%2Fpaths%2F~1posts~1%7Bpost_id%7D%2Fget>

    my $response = $resource->get('ID-HERE');

=item C<delete()>

L<Delete a post|https://api.mattermost.com/#tag/posts%2Fpaths%2F~1posts~1%7Bpost_id%7D%2Fdelete>

    my $response = $resource->delete('ID-HERE');

=item C<update()>

L<Update a post|https://api.mattermost.com/#tag/posts%2Fpaths%2F~1posts~1%7Bpost_id%7D%2Fput>

Fields not sent will be treated as blank (and unset). Use C<patch()> for
updating individual fields.

    my $response = $resource->update('ID-HERE', {
        # Optional parameters:
        is_pinned     => \0, # or \1 for true
        message       => '...',
        file_ids      => [ '...' ],
        has_reactions => \0, # or \1 for true
        props         => {},
    });

=item C<patch()>

L<Patch a post|https://api.mattermost.com/#tag/posts%2Fpaths%2F~1posts~1%7Bpost_id%7D~1patch%2Fput>

    my $response = $resource->patch('ID-HERE', {
        # Optional parameters:
        is_pinned     => \0, # or \1 for true
        message       => '...',
        file_ids      => [ '...' ],
        has_reactions => \0, # or \1 for true
        props         => {},
    });

=item C<thread()>

L<Get a thread|https://api.mattermost.com/#tag/posts%2Fpaths%2F~1posts~1%7Bpost_id%7D~1thread%2Fget>

    my $response = $resource->thread('ID-HERE');

=item C<files()>

L<Get file info for post|https://api.mattermost.com/#tag/posts%2Fpaths%2F~1posts~1%7Bpost_id%7D~1files~1info%2Fget>

    my $response = $resource->files('ID-HERE');

=item C<pin()>

L<Pin a post to the channel|https://api.mattermost.com/#tag/posts%2Fpaths%2F~1posts~1%7Bpost_id%7D~1pin%2Fpost>

    my $response = $resource->pin('ID-HERE');

=item C<unpin()>

L<Unpin a post from the channel|https://api.mattermost.com/#tag/posts%2Fpaths%2F~1posts~1%7Bpost_id%7D~1unpin%2Fpost>

    my $response = $resource->unpin('ID-HERE');

=item C<reactions()>

L<Get a list of reactions to a post|https://api.mattermost.com/#tag/reactions%2Fpaths%2F~1posts~1%7Bpost_id%7D~1reactions%2Fget>

    my $response = $resource->reactions('ID-HERE');

=item C<perform_action()>

L<Perform a post action|https://api.mattermost.com/#tag/posts%2Fpaths%2F~1posts~1%7Bpost_id%7D~1actions~1%7Baction_id%7D%2Fpost>

    my $response = $resource->perform_action('POST-ID-HERE', 'REACTION-ID-HERE');

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

