package WebService::Mattermost::V4::API::Object::User::Preference;

use Moo;
use Types::Standard qw(Maybe Str);

extends 'WebService::Mattermost::V4::API::Object';
with    qw(
    WebService::Mattermost::V4::API::Object::Role::BelongingToUser
    WebService::Mattermost::V4::API::Object::Role::Name
);

################################################################################

has [ qw(category value) ] => (is => 'ro', isa => Maybe[Str], lazy => 1, builder => 1);

################################################################################

sub _build_category { shift->raw_data->{category} }
sub _build_value    { shift->raw_data->{value}    }

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::User::Preference

=head1 DESCRIPTION

=head2 ATTRIBUTES

=over 4

=item C<category>

=item C<value>

=back

=head1 SEE ALSO

=over 4

=item C<WebService::Mattermost::V4::API::Object::Role::BelongingToUser>

=item C<WebService::Mattermost::V4::API::Object::Role::Name>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

