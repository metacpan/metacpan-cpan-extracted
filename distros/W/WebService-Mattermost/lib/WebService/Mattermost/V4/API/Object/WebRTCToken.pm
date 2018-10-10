package WebService::Mattermost::V4::API::Object::WebRTCToken;

use Moo;
use Types::Standard qw(Str Maybe);

extends 'WebService::Mattermost::V4::API::Object';

################################################################################

has [ qw(
    token
    gateway_url
    stun_uri
    turn_uri
    turn_password
    turn_username
) ] => (is => 'ro', isa => Str, lazy => 1, builder => 1);

################################################################################

sub _build_token          { shift->raw_data->{token}         }
sub _build_gateway_url    { shift->raw_data->{gateway_url}   }
sub _build_stun_uri       { shift->raw_data->{stun_url}      }
sub _build_turn_uri       { shift->raw_data->{turn_url}      }
sub _build_turn_password  { shift->raw_data->{turn_password} }
sub _build_turn_username  { shift->raw_data->{turn_username} }

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::WebRTCToken

=head1 DESCRIPTION

Details a Mattermost WebRTC token object.

=head2 ATTRIBUTES

=over 4

=over 4

=item C<token>

=item C<gateway_url>

=item C<stun_uri>

=item C<turn_uri>

=item C<turn_password>

=item C<turn_username>

=back

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

