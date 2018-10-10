package WebService::Mattermost::V4::API::Object::Role::ExpiresAt;

use Moo::Role;
use Types::Standard qw(InstanceOf Int Maybe);

#requires qw(_from_epoch raw_data);

################################################################################

has expires_at => (is => 'ro', isa => Maybe[Int],                    lazy => 1, builder => 1);
has expires    => (is => 'ro', isa => Maybe[InstanceOf['DateTime']], lazy => 1, builder => 1);

################################################################################

sub _build_expires_at {
    my $self = shift;

    return $self->raw_data->{expires_at};
}

sub _build_expires {
    my $self = shift;

    return $self->_from_epoch($self->expires_at);
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::Role::ExpiresAt

=head1 DESCRIPTION

Attach common timestamps to a v4::Object object.

=head2 ATTRIBUTES

=over 4

=item C<expires_at>

UNIX timestamp.

=item C<expires>

C<DateTime> object.

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

