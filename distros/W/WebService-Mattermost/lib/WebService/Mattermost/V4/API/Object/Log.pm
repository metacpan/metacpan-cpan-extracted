package WebService::Mattermost::V4::API::Object::Log;

use Moo;
use Types::Standard qw(Maybe InstanceOf Int Str);

extends 'WebService::Mattermost::V4::API::Object';
with    'WebService::Mattermost::V4::API::Object::Role::Level';

################################################################################

has [ qw(caller msg ts) ] => (is => 'ro', isa => Maybe[Str],                    lazy => 1, builder => 1);
has timestamp             => (is => 'ro', isa => Maybe[InstanceOf['DateTime']], lazy => 1, builder => 1);

################################################################################

sub _build_caller { shift->raw_data->{caller} }
sub _build_msg    { shift->raw_data->{msg}    }
sub _build_ts     { shift->raw_data->{ts}     }

sub _build_timestamp {
    my $self = shift;

    return $self->_from_epoch($self->ts);
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::Log

=head1 DESCRIPTION

Details a Mattermost Log object.

=head2 ATTRIBUTES

=over 4

=item C<caller>

=item C<msg>

=item C<ts>

UNIX timestamp.

=item C<timestamp>

DateTime.

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

