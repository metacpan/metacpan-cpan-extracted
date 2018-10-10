package WebService::Mattermost::V4::API::Object::Response;

use Moo;

extends 'WebService::Mattermost::V4::API::Object';
with    qw(
    WebService::Mattermost::V4::API::Object::Role::ID
    WebService::Mattermost::V4::API::Object::Role::Message
    WebService::Mattermost::V4::API::Object::Role::RequestID
    WebService::Mattermost::V4::API::Object::Role::StatusCode
);

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::Response

=head1 DESCRIPTION

Details a generic response from Mattermost.

=head1 SEE ALSO

=over 4

=item C<WebService::Mattermost::V4::API::Object::Role::ID>

=item C<WebService::Mattermost::V4::API::Object::Role::Message>

=item C<WebService::Mattermost::V4::API::Object::Role::RequestID>

=item C<WebService::Mattermost::V4::API::Object::Role::StatusCode>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

