package WebService::Mattermost::V4::API::Object::Role::ID;

use Moo::Role;
use Types::Standard qw(Maybe Str);

#requires 'raw_data';

################################################################################

has id => (is => 'ro', isa => Maybe[Str], lazy => 1, builder => 1);

################################################################################

sub _build_id {
    my $self = shift;

    return $self->raw_data->{id};
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::Role::ID

=head1 DESCRIPTION

Attach an ID to a v4::Object object.

=head2 ATTRIBUTES

=over 4

=item C<id>

UUID.

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

