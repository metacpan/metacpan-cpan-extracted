package WebService::Mattermost::V4::API::Object::Audit;

use Moo;
use Types::Standard qw(Maybe Str);

extends 'WebService::Mattermost::V4::API::Object';
with    qw(
    WebService::Mattermost::V4::API::Object::Role::BelongingToUser
    WebService::Mattermost::V4::API::Object::Role::CreatedAt
    WebService::Mattermost::V4::API::Object::Role::ID
);

################################################################################

has [ qw(
    action
    extra_info
    session_id
) ] => (is => 'ro', isa => Str, lazy => 1, builder => 1);

################################################################################

sub _build_action     { shift->raw_data->{action}     }
sub _build_extra_info { shift->raw_data->{extra_info} }
sub _build_session_id { shift->raw_data->{session_id} }

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::Audit

=head1 DESCRIPTION

Details a generic response from Mattermost.

=head1 SEE ALSO

=over 4

=item C<WebService::Mattermost::V4::API::Object::Role::BelongingToUser>

=item C<WebService::Mattermost::V4::API::Object::Role::CreatedAt>

=item C<WebService::Mattermost::V4::API::Object::Role::ID>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

