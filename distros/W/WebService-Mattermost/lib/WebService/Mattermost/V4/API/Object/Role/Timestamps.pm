package WebService::Mattermost::V4::API::Object::Role::Timestamps;

use Moo::Role;
use Types::Standard qw(InstanceOf Int Maybe);

with qw(
    WebService::Mattermost::V4::API::Object::Role::CreatedAt
    WebService::Mattermost::V4::API::Object::Role::UpdatedAt
);

################################################################################

has [ qw(
    delete_at
) ]  => (is => 'ro', isa => Maybe[Int], lazy => 1, builder => 1);

has [ qw(
    deleted_at
) ] => (is => 'ro', isa => Maybe[InstanceOf['DateTime']], lazy => 1, builder => 1);

################################################################################

sub _build_delete_at {
    my $self = shift;

    return $self->raw_data->{delete_at};
}

sub _build_deleted_at {
    my $self = shift;

    return $self->_from_epoch($self->raw_data->{delete_at});
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::Role::Timestamps

=head1 DESCRIPTION

Attach common timestamps to a v4::Object object.

=head2 ATTRIBUTES

=over 4

=item C<delete_at>

UNIX timestamp.

=item C<deleted_at>

C<DateTime> object.

=back

=head1 SEE ALSO

=over 4

=item C<WebService::Mattermost::V4::API::Object::Role::CreatedAt>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

