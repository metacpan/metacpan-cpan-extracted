package WebService::Mattermost::V4::API::Resource::Jobs;

use Moo;

extends 'WebService::Mattermost::V4::API::Resource';

################################################################################

sub all {
    my $self = shift;
    my $args = shift;

    return $self->_single_view_get({
        view       => 'Job',
        parameters => $args,
    });
}

sub create {
    my $self = shift;
    my $args = shift;

    return $self->_single_view_post({
        view       => 'Job',
        parameters => $args,
        required   => [ 'type' ],
    });
}

sub get_by_type {
    my $self = shift;
    my $type = shift;

    unless ($type) {
        return $self->_error_return('The first argument must be a job type');
    }

    return $self->_get({
        view     => 'Job',
        endpoint => 'type/%s',
        ids      => [ $type ],
    });
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::Jobs

=head1 DESCRIPTION

=head2 USAGE

    use WebService::Mattermost;

    my $mm = WebService::Mattermost->new({
        authenticate => 1,
        username     => 'me@somewhere.com',
        password     => 'hunter2',
        base_url     => 'https://my.mattermost.server.com/api/v4/',
    });

    my $resource = $mm->api->teams->jobs;

=head2 METHODS

=over 4

=item C<all()>

L<Get the jobs|https://api.mattermost.com/#tag/jobs%2Fpaths%2F~1jobs%2Fget>

Get all the jobs.

    my $response = $resource->all({
        # Optional arguments
        page     => 0,
        per_page => 60,
    });

=item C<create()>

L<Create a new job|https://api.mattermost.com/#tag/jobs%2Fpaths%2F~1jobs%2Fpost>

    my $response = $resource->create({
        # Required arguments
        type => 'JOB-TYPE',

        # Optional arguments
        data => {},
    });

=item C<get_by_type()>

L<https://api.mattermost.com/#tag/jobs%2Fpaths%2F~1jobs~1type~1%7Btype%7D%2Fget>

    my $response = $resource->get_by_type('JOB-TYPE-HERE');

=back

=head1 SEE ALSO

=over 4

=item L<Official Jobs documentation|https://api.mattermost.com/#tag/jobs>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

