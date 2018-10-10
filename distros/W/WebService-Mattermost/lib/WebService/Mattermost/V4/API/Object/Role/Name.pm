package WebService::Mattermost::V4::API::Object::Role::Name;

use Moo::Role;
use Types::Standard qw(Maybe Str);

################################################################################

has name => (is => 'ro', isa => Maybe[Str], lazy => 1, builder => 1);

################################################################################

sub _build_name {
    my $self = shift;

    return $self->raw_data->{name};
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::Role::Name

=head1 DESCRIPTION

Attach a name to a v4::Object object.

=head2 ATTRIBUTES

=over 4

=item C<name>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

