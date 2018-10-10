package WebService::Mattermost::V4::API::Resource::Reactions;

use Moo;

extends 'WebService::Mattermost::V4::API::Resource';

################################################################################

around [ qw(react) ] => sub {
    my $orig = shift;
    my $self = shift;
    my $id   = shift;

    return $self->validate_id($orig, $id, @_);
};

sub react {
    my $self       = shift;
    my $post_id    = shift;
    my $emoji_name = shift;
    my $user_id    = shift;

    unless ($emoji_name && $user_id) {
        return $self->_error_return('The second and third arguments must be an emoji name and a user ID');
    }

    return $self->_post({
        parameters => {
            post_id    => $post_id,
            emoji_name => $emoji_name,
            user_id    => $user_id,
        },
    });
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::Reactions

=head1 DESCRIPTION

=head2 USAGE

    use WebService::Mattermost;

    my $mm = WebService::Mattermost->new({
        authenticate => 1,
        username     => 'me@somewhere.com',
        password     => 'hunter2',
        base_url     => 'https://my.mattermost.server.com/api/v4/',
    });

    my $resource = $mm->api->reactions;

=head2 METHODS

=over 4

=item C<react()>

L<Create a reaction|https://api.mattermost.com/#tag/reactions%2Fpaths%2F~1reactions%2Fpost>

    my $response = $resource->react('POST-ID-HERE', 'EMOJI-NAME-HERE', 'USER-ID-HERE');

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

