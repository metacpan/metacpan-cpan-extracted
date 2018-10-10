package WebService::Mattermost::V4::API::Object::Role::Description;

use Moo::Role;
use Types::Standard qw(Maybe Str);

#requires 'raw_data';

################################################################################

has description => (is => 'ro', isa => Maybe[Str], lazy => 1, builder => 1);

################################################################################

sub _build_description {
    my $self = shift;

    return $self->raw_data->{description};
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::Role::Description

=head1 DESCRIPTION

Attach a description to a v4::Object object.

=head2 ATTRIBUTES

=over 4

=item C<description>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

