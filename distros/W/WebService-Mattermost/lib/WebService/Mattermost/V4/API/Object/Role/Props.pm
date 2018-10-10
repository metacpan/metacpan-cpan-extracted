package WebService::Mattermost::V4::API::Object::Role::Props;

use Moo::Role;
use Types::Standard qw(HashRef Maybe);

#requires 'raw_data';

################################################################################

has props => (is => 'ro', isa => Maybe[HashRef], lazy => 1, builder => 1);

################################################################################

sub _build_props {
    my $self = shift;

    return $self->raw_data->{props};
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::Role::Props

=head1 DESCRIPTION

Attach a props HashRef to a v4::Object object.

=head2 ATTRIBUTES

=over 4

=item C<props>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

