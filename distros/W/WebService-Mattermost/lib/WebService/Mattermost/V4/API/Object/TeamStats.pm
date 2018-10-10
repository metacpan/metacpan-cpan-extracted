package WebService::Mattermost::V4::API::Object::TeamStats;

use Moo;
use Types::Standard qw(Int Maybe);

extends 'WebService::Mattermost::V4::API::Object';
with    qw(
    WebService::Mattermost::V4::API::Object::Role::BelongingToTeam
);

################################################################################

has [ qw(
    active_member_count
    total_member_count
) ] => (is => 'ro', isa => Maybe[Int], lazy => 1, builder => 1);

################################################################################

sub _build_active_member_count { shift->raw_data->{active_member_count} }
sub _build_total_member_count  { shift->raw_data->{total_member_count}  }

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::TeamStats

=head1 DESCRIPTION

Details a Mattermost TeamStats object.

=head2 ATTRIBUTES

=over 4

=item C<total_member_count>

=item C<active_member_count>

=back

=head1 SEE ALSO

=over 4

=item C<WebService::Mattermost::V4::API::Object::Role::BelongingToUser>

=item C<WebService::Mattermost::V4::API::Object::Role::BelongingToTeam>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

