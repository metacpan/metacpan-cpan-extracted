package WebService::Mattermost::V4::API::Object::Role::Level;

use Moo::Role;
use Types::Standard qw(Maybe Str);

################################################################################

has level => (is => 'ro', isa => Maybe[Str], lazy => 1, builder => 1);

################################################################################

sub _build_level {
    my $self = shift;

    return $self->raw_data->{level};
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::Role::Level

=head1 DESCRIPTION

Attach an Level to a v4::Object object.

=head2 ATTRIBUTES

=over 4

=item C<level>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

