package WebService::Mattermost::V4::API::Resource::Analytics;

use Moo;

extends 'WebService::Mattermost::V4::API::Resource';

################################################################################

sub get {
    my $self = shift;
    my $args = shift;

    return $self->_get({
        endpoint   => 'old',
        parameters => $args,
        view       => 'Analytics::Old',
    });
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::Analytics

=head1 DESCRIPTION

=head2 USAGE

    use WebService::Mattermost;

    my $mm = WebService::Mattermost->new({
        authenticate => 1,
        username     => 'me@somewhere.com',
        password     => 'hunter2',
        base_url     => 'https://my.mattermost.server.com/api/v4/',
    });

    my $resource = $mm->api->analytics;

=head2 METHODS

=over 4

=item C<get()>

L<Get analytics|https://api.mattermost.com/#tag/system%2Fpaths%2F~1analytics~1old%2Fget>

    my $response = $resource->get({
        # Optional parameters:
        name    => 'standard', # 'post_counts_day', 'user_counts_with_posts_day', 'extra_counts'
        team_id => 'TEAM-ID-HERE',
    });

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

