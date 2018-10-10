package WebService::Mattermost::V4::API::Object::User::Status;

use Moo;
use Types::Standard qw(Maybe Bool);

extends 'WebService::Mattermost::V4::API::Object';
with    qw(
    WebService::Mattermost::V4::API::Object::Role::BelongingToUser
    WebService::Mattermost::V4::API::Object::Role::LastActivityAt
    WebService::Mattermost::V4::API::Object::Role::Status
);

################################################################################

has manual => (is => 'ro', isa => Maybe[Bool], lazy => 1, builder => 1);

################################################################################

sub _build_manual {
    return shift->raw_data->{manual} ? 1 : 0;
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::User::Status

=head1 DESCRIPTION

Describe's a User's status.

=head2 ATTRIBUTES

=over 4

=item C<manual>

Was the status set manually?

=back

=head1 SEE ALSO

=over 4

=item C<WebService::Mattermost::V4::API::Object::Role::BelongingToUser>

=item C<WebService::Mattermost::V4::API::Object::Role::LastActivityAt>

=item C<WebService::Mattermost::V4::API::Object::Role::Status>

=back

