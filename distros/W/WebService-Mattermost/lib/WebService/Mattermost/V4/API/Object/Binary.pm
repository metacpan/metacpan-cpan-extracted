package WebService::Mattermost::V4::API::Object::Binary;

use Moo;
use Types::Standard qw(Maybe Str);

extends 'WebService::Mattermost::V4::API::Object';

################################################################################

has content => (is => 'ro', isa => Maybe[Str], lazy => 1, builder => 1);

################################################################################

sub _build_content { shift->raw_content }

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::Binary

=head1 DESCRIPTION

Contains raw binary for a file returned from Mattermost.

=head2 ATTRIBUTES

=over 4

=item C<content>

Raw binary content.

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

