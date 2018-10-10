package WebService::Mattermost::V4::API::Object::Role::Roles;

use Moo::Role;
use Types::Standard qw(Maybe Str);

#requires 'raw_data';

################################################################################

has roles => (is => 'ro', isa => Maybe[Str], lazy => 1, builder => 1);

################################################################################

sub _build_roles {
    my $self = shift;

    return $self->raw_data->{roles};
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::Role::Timestamps

=head1 DESCRIPTION

Attach an Roles to a v4::Object object.

=head2 ATTRIBUTES

=over 4

=item C<roles>

String.

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

