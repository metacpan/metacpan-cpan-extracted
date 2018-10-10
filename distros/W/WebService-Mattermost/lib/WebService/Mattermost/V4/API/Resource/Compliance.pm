package WebService::Mattermost::V4::API::Resource::Compliance;

use Moo;
use Types::Standard 'Str';

extends 'WebService::Mattermost::V4::API::Resource';

################################################################################

has view_name => (is => 'ro', isa => Str, default => 'Compliance::Report');

################################################################################

sub create_report {
    my $self = shift;

    return $self->_post({ endpoint => 'reports' });
}

sub get_reports {
    my $self = shift;
    my $args = shift;

    return $self->_get({
        view       => 'Compliance::Report',
        endpoint   => 'reports',
        parameters => $args,
    });
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::Compliance

=head1 DESCRIPTION

=head2 USAGE

    use WebService::Mattermost;

    my $mm = WebService::Mattermost->new({
        authenticate => 1,
        username     => 'me@somewhere.com',
        password     => 'hunter2',
        base_url     => 'https://my.mattermost.server.com/api/v4/',
    });

    my $resource = $mm->api->compliance;

=head2 METHODS

=over 4

=item C<create_report()>

Create a new compliance report.

    my $response = $resource->create_report();

=item C<get_reports()>

Get all compliance reports.

    my $response = $resource->get_reports({
        # Optional parameters
        page     => 0,  # default values
        per_page => 60,
    });

=back

=head1 SEE ALSO

=over 4

=item L<Official compliance documentation|https://api.mattermost.com/#tag/compliance>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

