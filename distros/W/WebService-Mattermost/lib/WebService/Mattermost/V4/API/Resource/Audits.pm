package WebService::Mattermost::V4::API::Resource::Audits;

use Moo;
use Types::Standard 'Str';

extends 'WebService::Mattermost::V4::API::Resource';

################################################################################

has view_name => (is => 'ro', isa => Str, default => 'Audit');

################################################################################

sub get {
    my $self = shift;
    my $args = shift;

    return $self->_get({ parameters => $args });
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::Audits

=head1 DESCRIPTION

=head2 USAGE

    use WebService::Mattermost;

    my $mm = WebService::Mattermost->new({
        authenticate => 1,
        username     => 'me@somewhere.com',
        password     => 'hunter2',
        base_url     => 'https://my.mattermost.server.com/api/v4/',
    });

    my $resource = $mm->api->audits;

=head2 METHODS

=over 4

=item C<get()>

L<Get audits|https://api.mattermost.com/#tag/system%2Fpaths%2F~1audits%2Fget>

    my $response = $resource->get({
        # Optional parameters:
        page     => 0,
        per_page => 60,
    });

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

