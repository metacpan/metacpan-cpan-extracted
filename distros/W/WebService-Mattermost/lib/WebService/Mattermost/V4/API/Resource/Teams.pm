package WebService::Mattermost::V4::API::Resource::Teams;

use Moo;

extends 'WebService::Mattermost::V4::API::Resource';

################################################################################

sub create {
    my $self = shift;
    my $args = shift;

    return $self->_single_view_post({
        parameters => $args,
        required   => [ qw(name display_name type) ],
    });
}

sub list {
    my $self = shift;
    my $args = shift;

    return $self->_get({
        view       => 'Team',
        parameters => $args,
    });
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::Teams

=head1 DESCRIPTION

=head2 USAGE

    use WebService::Mattermost;

    my $mm = WebService::Mattermost->new({
        authenticate => 1,
        username     => 'me@somewhere.com',
        password     => 'hunter2',
        base_url     => 'https://my.mattermost.server.com/api/v4/',
    });

    my $resource = $mm->api->teams;

=head2 METHODS

=over 4

=item C<create()>

L<Create a team|https://api.mattermost.com/#tag/teams%2Fpaths%2F~1teams%2Fpost>

    my $response = $resource->create({
        # Required parameters:
        name         => '...',
        type         => 'O', # O for open, I for invite only
        display_name => '...',
    });

=item C<list()>

L<Get teams|https://api.mattermost.com/#tag/teams%2Fpaths%2F~1teams%2Fget>

    my $response = $resource->list({
        # Optional parameters:
        page     => 0,
        per_page => 60,
    });

=back

