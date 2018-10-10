package WebService::Mattermost::V4::API::Object::User::Session;

use Moo;
use Types::Standard qw(ArrayRef Bool Maybe Str);

extends 'WebService::Mattermost::V4::API::Object';
with    qw(
    WebService::Mattermost::V4::API::Object::Role::BelongingToUser
    WebService::Mattermost::V4::API::Object::Role::CreatedAt
    WebService::Mattermost::V4::API::Object::Role::ExpiresAt
    WebService::Mattermost::V4::API::Object::Role::ID
    WebService::Mattermost::V4::API::Object::Role::LastActivityAt
    WebService::Mattermost::V4::API::Object::Role::Props
    WebService::Mattermost::V4::API::Object::Role::Roles
);

################################################################################

has device_id    => (is => 'ro', isa => Maybe[Str],      lazy => 1, builder => 1);
has is_oauth     => (is => 'ro', isa => Maybe[Bool],     lazy => 1, builder => 1);
has team_members => (is => 'ro', isa => Maybe[ArrayRef], lazy => 1, builder => 1);
has token        => (is => 'ro', isa => Maybe[Str],      lazy => 1, builder => 1);

################################################################################

sub _build_device_id    { shift->raw_data->{device_id}        }
sub _build_is_oauth     { shift->raw_data->{is_oauth} ? 1 : 0 }
sub _build_team_members { shift->raw_data->{team_members}     }
sub _build_token        { shift->raw_data->{token}            }

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::User::Session

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item C<device_id>

=item C<is_oauth>

=item C<team_members>

=item C<token>

=back

=head1 SEE ALSO

=over 4

=item C<WebService::Mattermost::V4::API::Object::Role::BelongingToUser>

=item C<WebService::Mattermost::V4::API::Object::Role::CreatedAt>

=item C<WebService::Mattermost::V4::API::Object::Role::ExpiresAt>

=item C<WebService::Mattermost::V4::API::Object::Role::ID>

=item C<WebService::Mattermost::V4::API::Object::Role::LastActivityAt>

=item C<WebService::Mattermost::V4::API::Object::Role::Props>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

