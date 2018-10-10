package WebService::Mattermost::API;

use Moo;
use Types::Standard qw(InstanceOf Str);

use WebService::Mattermost::V4::API;

################################################################################

has base_url => (is => 'ro', isa => Str, required => 1);

has v4 => (is => 'ro', isa => InstanceOf['WebService::Mattermost::V4::API'], lazy => 1, builder => 1);

################################################################################

sub _build_v4 {
    my $self = shift;

    return WebService::Mattermost::V4::API->new({
        base_url => $self->base_url,
    });
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::API - wrapper for Mattermost API version integrations.

=head1 DESCRIPTION

=head2 ATTRIBUTES

=over 4

=item C<base_url>

The API's base URL.

=item C<v4>

A wrapper for the Mattermost V4 API.

=back

=head1 SEE ALSO

=over 4

=item C<WebService::Mattermost::V4::API>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

