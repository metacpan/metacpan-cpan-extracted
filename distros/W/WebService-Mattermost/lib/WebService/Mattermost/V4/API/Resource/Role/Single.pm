package WebService::Mattermost::V4::API::Resource::Role::Single;

use Moo::Role;
use Types::Standard 'Str';

################################################################################

has id => (is => 'rw', isa => Str, required => 0);

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::Role::Single

=head1 DESCRIPTION

To be included in API resources for a single result object (i.e. something with
a unique identifier).

The C<id> attribute may be overridden by an ID parameter being passed to a
method call (which will take precedence over the C<id> attribute).

=head1 ATTRIBUTES

=over 4

=item C<id>

String.

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

