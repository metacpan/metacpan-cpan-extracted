package WebService::Mattermost::V4::API::Object::TeamMember;

use Moo;

extends 'WebService::Mattermost::V4::API::Object';
with    qw(
    WebService::Mattermost::V4::API::Object::Role::BelongingToUser
    WebService::Mattermost::V4::API::Object::Role::BelongingToTeam
    WebService::Mattermost::V4::API::Object::Role::Roles
);

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::TeamMember

=head1 DESCRIPTION

Details a Mattermost TeamMember object.

=head1 SEE ALSO

=over 4

=item C<WebService::Mattermost::V4::API::Object::Role::BelongingToUser>

=item C<WebService::Mattermost::V4::API::Object::Role::BelongingToTeam>

=item C<WebService::Mattermost::V4::API::Object::Role::Roles>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

