package WebService::Mattermost::V4::API::Object::Application;

use Moo;
use Types::Standard qw(ArrayRef Bool Maybe Str);

extends 'WebService::Mattermost::V4::API::Object';
with    qw(
    WebService::Mattermost::V4::API::Object::Role::Description
    WebService::Mattermost::V4::API::Object::Role::ID
    WebService::Mattermost::V4::API::Object::Role::Name
    WebService::Mattermost::V4::API::Object::Role::CreatedAt
    WebService::Mattermost::V4::API::Object::Role::UpdatedAt
);

################################################################################

has [ qw(
    client_secret
    icon_url
    homepage
) ]            => (is => 'ro', isa => Maybe[Str],  lazy => 1, builder => 1);
has is_trusted => (is => 'ro', isa => Maybe[Bool], lazy => 1, builder => 1);

################################################################################

sub _build_client_secret { shift->raw_data->{client_secret} }
sub _build_icon_url      { shift->raw_data->{icon_url}      }
sub _build_homepage      { shift->raw_data->{homepage}      }
sub _build_is_trusted    { shift->raw_data->{is_trusted}    }

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::Application

=head1 DESCRIPTION

Details a Mattermost Application object.

=head2 ATTRIBUTES

=over 4

=item C<client_secret>

=item C<icon_url>

=item C<homepage>

=item C<is_trusted>

=back

=head1 SEE ALSO

=over 4

=item C<WebService::Mattermost::V4::API::Object::Role::ID>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

