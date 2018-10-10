package WebService::Mattermost::V4::API::Object::Role::StatusCode;

use Moo::Role;
use Types::Standard qw(Int Maybe);

################################################################################

has status_code => (is => 'ro', isa => Maybe[Int], lazy => 1, builder => 1);

################################################################################

sub _build_status_code {
    my $self = shift;

    return $self->raw_data->{status_code};
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::Role::StatusCode

=head1 DESCRIPTION

Attach a StatusCode to a v4::Object object.

=head2 ATTRIBUTES

=over 4

=item C<status_code>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

