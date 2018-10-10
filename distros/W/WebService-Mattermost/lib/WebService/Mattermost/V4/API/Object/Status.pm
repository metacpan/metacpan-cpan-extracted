package WebService::Mattermost::V4::API::Object::Status;

use Moo;
use Types::Standard qw(Str Int);

extends 'WebService::Mattermost::V4::API::Object';
with    'WebService::Mattermost::V4::API::Object::Role::Status';

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::Status

=head1 DESCRIPTION

Details a Mattermost Status object.

=head1 SEE ALSO

=over 4

=item C<WebService::Mattermost::V4::API::Object::Role::Status>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

