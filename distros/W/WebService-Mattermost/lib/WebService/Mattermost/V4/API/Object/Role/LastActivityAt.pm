package WebService::Mattermost::V4::API::Object::Role::LastActivityAt;

use Moo::Role;
use Types::Standard qw(InstanceOf Int Maybe);

#requires qw(_from_epoch raw_data);

################################################################################

has last_activity_at => (is => 'ro', isa => Maybe[Int],                    lazy => 1, builder => 1);
has last_activity    => (is => 'ro', isa => Maybe[InstanceOf['DateTime']], lazy => 1, builder => 1);

################################################################################

sub _build_last_activity_at {
    my $self = shift;

    return $self->raw_data->{last_activity_at};
}

sub _build_last_activity {
    my $self = shift;

    return $self->_from_epoch($self->last_activity_at);
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::Role::LastActivityAt

=head1 DESCRIPTION

Attach common timestamps to a v4::Object object.

=head2 ATTRIBUTES

=over 4

=item C<last_activity_at>

UNIX timestamp.

=item C<last_activity>

C<DateTime> object.

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

