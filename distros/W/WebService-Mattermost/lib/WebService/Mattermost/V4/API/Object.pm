package WebService::Mattermost::V4::API::Object;

use DateTime;
use Moo;
use Types::Standard qw(HashRef InstanceOf Str);

use WebService::Mattermost::V4::API;

with 'WebService::Mattermost::Role::Returns';

################################################################################

has [ qw(auth_token base_url) ] => (is => 'ro', isa => Str,     required => 1);
has raw_data                    => (is => 'ro', isa => HashRef, required => 1);

has api => (is => 'ro', isa => InstanceOf['WebService::Mattermost::V4::API'], lazy => 1, builder => 1);

################################################################################

sub _from_epoch {
    my $self           = shift;
    my $unix_timestamp = shift;

    return undef unless $unix_timestamp;

    # The timestamp is too precise - trim away the end
    $unix_timestamp =~ s/...$//s;

    return DateTime->from_epoch(epoch => $unix_timestamp);
}

sub _related_args {
    my $self = shift;
    my $args = shift;

    return {
        auth_token => $self->auth_token,
        base_url   => $self->base_url,
        raw_data   => $args,
    };
}

################################################################################

sub _build_api {
    my $self = shift;

    return WebService::Mattermost::V4::API->new({
        auth_token => $self->auth_token,
        base_url   => $self->base_url,
    });
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object

=head1 DESCRIPTION

Base class for wrappers for results returned from the Mattermost API.

=head2 METHODS

=over 4

=item C<_from_epoch()>

Converts a UNIX timestamp from Mattermost to a DateTime object. The last three
characters of the timestamp are trimmed to make it the expected length.

=back

=head2 ATTRIBUTES

=over 4

=item C<raw_data>

The raw response from Mattermost.

=item C<auth_token>

The current session's auth token, for rebuilding the API.

=item C<base_url>

The server's base URL.

=item C<api>

API access for the Object classes.

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

