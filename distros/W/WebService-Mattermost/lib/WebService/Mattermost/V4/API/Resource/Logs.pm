package WebService::Mattermost::V4::API::Resource::Logs;

use Moo;
use Types::Standard 'Str';

extends 'WebService::Mattermost::V4::API::Resource';

################################################################################

has view_name => (is => 'ro', isa => Str, default => 'Log');

################################################################################

sub get {
    my $self = shift;

    return $self->_get();
}

sub add_message {
    my $self = shift;
    my $args = shift;

    return $self->_post({
        parameters => $args,
        required   => [ qw(level message) ],
        view       => 'NewLogEntry',
    });
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::Logs

=head1 DESCRIPTION

=head2 USAGE

    use WebService::Mattermost;

    my $mm = WebService::Mattermost->new({
        authenticate => 1,
        username     => 'me@somewhere.com',
        password     => 'hunter2',
        base_url     => 'https://my.mattermost.server.com/api/v4/',
    });

    my $resource = $mm->api->logs;

=head2 METHODS

=over 4

=item C<get()>

L<Get logs|https://api.mattermost.com/#tag/system%2Fpaths%2F~1logs%2Fget>

    my $response = $resource->get();

=item C<add_message()>

L<Add log message|https://api.mattermost.com/#tag/system%2Fpaths%2F~1logs%2Fpost>

    my $response = $resource->add_message({
        # Required parameters:
        level   => 'ERROR', # or DEBUG
        message => '...',
    });

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

