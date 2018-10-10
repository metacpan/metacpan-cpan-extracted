package WebService::Mattermost::V4::API::Object::NewLogEntry;

use Moo;
use Types::Standard qw(Maybe InstanceOf Int Str);

extends 'WebService::Mattermost::V4::API::Object';
with    'WebService::Mattermost::V4::API::Object::Role::Message';

################################################################################

has level => (is => 'ro', isa => Maybe[Str], lazy => 1, builder => 1);

################################################################################

sub _build_level  { shift->raw_data->{level}  }

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::NewLogEntry

=head1 DESCRIPTION

Details a Mattermost NewLogEntry object.

=head1 SEE ALSO

=over 4

=item C<WebService::Mattermost::V4::API::Object::Role::Message>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

