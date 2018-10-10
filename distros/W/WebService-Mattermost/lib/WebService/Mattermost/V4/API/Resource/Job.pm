package WebService::Mattermost::V4::API::Resource::Job;

use Moo;

extends 'WebService::Mattermost::V4::API::Resource';

################################################################################

around [ qw(get cancel) ] => sub {
    my $orig = shift;
    my $self = shift;
    my $id   = shift;

    return $self->_validate_id($orig, $id, @_);
};

sub get {
    my $self = shift;
    my $id   = shift;

    return $self->_single_view_get({
        view     => 'Job',
        endpoint => '%s',
        ids      => [ $id ],
    });
}

sub cancel {
    my $self = shift;
    my $id   = shift;

    return $self->_single_view_post({
        view     => 'Job',
        endpoint => '%s/cancel',
        ids      => [ $id ],
    });
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::Job

=head1 DESCRIPTION

=head2 USAGE

    use WebService::Mattermost;

    my $mm = WebService::Mattermost->new({
        authenticate => 1,
        username     => 'me@somewhere.com',
        password     => 'hunter2',
        base_url     => 'https://my.mattermost.server.com/api/v4/',
    });

    my $resource = $mm->api->teams->job;

=head2 METHODS

=over 4

=item C<get()>

L<Get a job|https://api.mattermost.com/#tag/jobs%2Fpaths%2F~1jobs~1%7Bjob_id%7D%2Fget>

    my $response = $resource->get('JOB-ID-HERE');

=item C<cancel()>

L<Cancel a job|https://api.mattermost.com/#tag/jobs%2Fpaths%2F~1jobs~1%7Bjob_id%7D~1cancel%2Fpost>

    my $response = $resource->cancel('JOB-ID-HERE');

=back

=head1 SEE ALSO

=over 4

=item L<Official Jobs documentation|https://api.mattermost.com/#tag/jobs>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

