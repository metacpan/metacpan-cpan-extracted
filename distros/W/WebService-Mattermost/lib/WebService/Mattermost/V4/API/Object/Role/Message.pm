package WebService::Mattermost::V4::API::Object::Role::Message;

use Moo::Role;
use Types::Standard qw(Maybe Str);

################################################################################

has message => (is => 'ro', isa => Maybe[Str], lazy => 1, builder => 1);

################################################################################

sub _build_message {
    my $self = shift;

    return $self->raw_data->{message};
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::Role::Message

=head1 DESCRIPTION

Attach an Message to a v4::Object object.

=head2 ATTRIBUTES

=over 4

=item C<message>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

