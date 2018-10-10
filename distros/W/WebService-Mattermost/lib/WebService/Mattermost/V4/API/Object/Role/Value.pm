package WebService::Mattermost::V4::API::Object::Role::Value;

use Moo::Role;
use Types::Standard qw(Maybe Str);

################################################################################

has value => (is => 'ro', isa => Maybe[Str], lazy => 1, builder => 1);

################################################################################

sub _build_value {
    my $self = shift;

    return $self->raw_data->{value};
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::Role::Value

=head1 DESCRIPTION

Attach a value to a v4::Object object.

=head2 ATTRIBUTES

=over 4

=item C<value>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

