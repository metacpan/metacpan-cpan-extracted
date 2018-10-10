package WebService::Mattermost::V4::API::Object::Role::UpdatedAt;

use Moo::Role;
use Types::Standard qw(InstanceOf Int Maybe);

################################################################################

has update_at  => (is => 'ro', isa => Maybe[Int],                    lazy => 1, builder => 1);
has updated_at => (is => 'ro', isa => Maybe[InstanceOf['DateTime']], lazy => 1, builder => 1);

################################################################################

sub _build_update_at {
    my $self = shift;

    return $self->raw_data->{update_at};
}

sub _build_updated_at {
    my $self = shift;

    return $self->_from_epoch($self->raw_data->{update_at});
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::Role::UpdatedAt

=head1 DESCRIPTION

Attach common timestamps to a v4::Object object.

=head2 ATTRIBUTES

=over 4

=item C<update_at>

UNIX timestamp.

=item C<updated_at>

C<DateTime> object.

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

