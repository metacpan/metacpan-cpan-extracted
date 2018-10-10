package WebService::Mattermost::V4::API::Object::Role::RequestID;

use Moo::Role;
use Types::Standard qw(Maybe Str);

################################################################################

has request_id => (is => 'ro', isa => Maybe[Str], lazy => 1, builder => 1);

################################################################################

sub _build_request_id {
    my $self = shift;

    return $self->raw_data->{request_id};
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::Role::RequestID

=head1 DESCRIPTION

Attach a RequestID to a v4::Object object.

=head2 ATTRIBUTES

=over 4

=item C<request_id>

UUID.

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

