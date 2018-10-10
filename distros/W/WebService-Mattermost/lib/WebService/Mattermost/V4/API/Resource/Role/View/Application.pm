package WebService::Mattermost::V4::API::Resource::Role::View::Application;

use Moo::Role;
use Types::Standard 'Str';

################################################################################

has view_name => (is => 'ro', isa => Str, default => 'Application');

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::Role::View::Application

=head1 DESCRIPTION

Set a resource as using the C<WebService::Mattermost::V4::API::Object::Application>
view.

=head1 ATTRIBUTES

=over 4

=item C<view_name>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

