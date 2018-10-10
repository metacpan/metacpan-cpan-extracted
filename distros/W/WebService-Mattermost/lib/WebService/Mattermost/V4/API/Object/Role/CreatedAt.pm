package WebService::Mattermost::V4::API::Object::Role::CreatedAt;

use Moo::Role;
use Types::Standard qw(InstanceOf Int Maybe);

#requires qw(_from_epoch raw_data);

################################################################################

has create_at  => (is => 'ro', isa => Maybe[Int],                    lazy => 1, builder => 1);
has created_at => (is => 'ro', isa => Maybe[InstanceOf['DateTime']], lazy => 1, builder => 1);

################################################################################

sub _build_create_at {
    my $self = shift;

    return $self->raw_data->{create_at};
}

sub _build_created_at {
    my $self = shift;

    return $self->_from_epoch($self->raw_data->{create_at});
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::Role::CreatedAt

=head1 DESCRIPTION

Attach common timestamps to a v4::Object object.

=head2 ATTRIBUTES

=over 4

=item C<create_at>

UNIX timestamp.

=item C<created_at>

C<DateTime> object.

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

