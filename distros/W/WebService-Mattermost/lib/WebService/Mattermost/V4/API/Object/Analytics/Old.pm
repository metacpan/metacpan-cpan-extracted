package WebService::Mattermost::V4::API::Object::Analytics::Old;

use Moo;
use Types::Standard qw(Int Maybe);

extends 'WebService::Mattermost::V4::API::Object';
with    qw(
    WebService::Mattermost::V4::API::Object::Role::Name
    WebService::Mattermost::V4::API::Object::Role::Value
);

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::Analytics::Old

=head1 DESCRIPTION

Details an old Mattermost analytics node.

=head1 SEE ALSO

=over 4

=item C<WebService::Mattermost::V4::API::Object::Role::Name>

=item C<WebService::Mattermost::V4::API::Object::Role::Value>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

