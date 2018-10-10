package WebService::Mattermost::V4::API::Object::Channel::Member;

use Moo;
use Types::Standard qw(HashRef InstanceOf Int Maybe Str);

extends 'WebService::Mattermost::V4::API::Object';
with    qw(
    WebService::Mattermost::V4::API::Object::Role::BelongingToUser
    WebService::Mattermost::V4::API::Object::Role::BelongingToChannel
    WebService::Mattermost::V4::API::Object::Role::Roles
);

################################################################################

has notify_props   => (is => 'ro', isa => Maybe[HashRef],                lazy => 1, builder => 1);
has last_update_at => (is => 'ro', isa => Maybe[Int],                    lazy => 1, builder => 1);
has last_viewed_at => (is => 'ro', isa => Maybe[Int],                    lazy => 1, builder => 1);
has mention_count  => (is => 'ro', isa => Maybe[Int],                    lazy => 1, builder => 1);
has msg_count      => (is => 'ro', isa => Maybe[Int],                    lazy => 1, builder => 1);
has last_update    => (is => 'ro', isa => Maybe[InstanceOf['DateTime']], lazy => 1, builder => 1);
has last_viewed    => (is => 'ro', isa => Maybe[InstanceOf['DateTime']], lazy => 1, builder => 1);

################################################################################

sub _build_notify_props   { shift->raw_data->{notify_props}   }
sub _build_last_update_at { shift->raw_data->{last_update_at} }
sub _build_last_viewed_at { shift->raw_data->{last_viewed_at} }
sub _build_mention_count  { shift->raw_data->{mention_count}  }
sub _build_msg_count      { shift->raw_data->{msg_count}      }

sub _build_last_update {
    my $self = shift;

    return $self->_from_epoch($self->last_update);
}

sub _build_last_viewed {
    my $self = shift;

    return $self->_from_epoch($self->last_update);
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::Channel::Member

=head1 DESCRIPTION

A member of a channel.

=head2 ATTRIBUTES

=over 4

=item C<notify_props>

=item C<last_update_at>

UNIX timestamp.

=item C<last_viewed_at>

UNIX timestamp.

=item C<mention_count>

=item C<msg_count>

=item C<last_update>

DateTime.

=item C<last_viewed>

DateTime.

=back

=head1 SEE ALSO

=over 4

=item C<WebService::Mattermost::V4::API::Object::Role::BelongingToUser>

=item C<WebService::Mattermost::V4::API::Object::Role::BelongingToChannel>

=item C<WebService::Mattermost::V4::API::Object::Role::Roles>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

