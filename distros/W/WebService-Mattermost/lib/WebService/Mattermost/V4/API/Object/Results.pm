package WebService::Mattermost::V4::API::Object::Results;

use Moo;
use Types::Standard qw(Maybe Str);

extends 'WebService::Mattermost::V4::API::Object';

################################################################################

has results => (is => 'ro', isa => Maybe[Str], lazy => 1, builder => 1);

################################################################################

sub _build_results { shift->raw_data->{results} }

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::Results

=head1 DESCRIPTION

Details a Mattermost Results object.

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

