package WebService::Mattermost::V4::API::Resource::Role::View::User;

use Moo::Role;
use Types::Standard 'Str';

################################################################################

has view_name => (is => 'ro', isa => Str, default => 'User');

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::Role::View::User

=head1 DESCRIPTION

Set a resource as using the C<WebService::Mattermost::V4::API::Object::User>
view.

=head1 ATTRIBUTES

=over 4

=item C<view_name>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

