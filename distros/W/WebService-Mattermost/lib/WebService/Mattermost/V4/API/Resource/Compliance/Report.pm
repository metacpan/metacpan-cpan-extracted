package WebService::Mattermost::V4::API::Resource::Compliance::Report;

use Moo;
use Types::Standard 'Str';

extends 'WebService::Mattermost::V4::API::Resource';

################################################################################

has view_name => (is => 'ro', isa => Str, default => 'Compliance::Report');

################################################################################

around [ qw(get download) ] => sub {
    my $orig = shift;
    my $self = shift;
    my $id   = shift;

    return $self->validate_id($orig, $id, @_);
};

sub get {
    my $self = shift;
    my $id   = shift;

    return $self->_single_view_get({
        endpoint => 'reports/%s',
        ids      => [ $id ],
    });
}

sub download {
    my $self = shift;
    my $id   = shift;

    return $self->_single_view_get({
        view     => 'Binary',
        endpoint => 'reports/%s/download',
        ids      => [ $id ],
    });
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::Compliance::Report

=head1 DESCRIPTION

=head2 USAGE

    use WebService::Mattermost;

    my $mm = WebService::Mattermost->new({
        authenticate => 1,
        username     => 'me@somewhere.com',
        password     => 'hunter2',
        base_url     => 'https://my.mattermost.server.com/api/v4/',
    });

    my $resource = $mm->api->compliance_report;

=head2 METHODS

=over 4

=item C<get()>

Get a compliance report by its ID.

    my $response = $resource->get('REPORT-ID-HERE');

=item C<download()>

Download a compliance report by its ID.

    my $response = $resource->download('REPORT-ID-HERE');

=back

=head1 SEE ALSO

=over 4

=item L<Official compliance documentation|https://api.mattermost.com/#tag/compliance>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

