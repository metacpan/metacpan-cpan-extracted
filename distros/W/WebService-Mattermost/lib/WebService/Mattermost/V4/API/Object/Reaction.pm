package WebService::Mattermost::V4::API::Object::Reaction;

use Moo;
use Types::Standard qw(InstanceOf Maybe Str);

use WebService::Mattermost::Helper::Alias 'view';

extends 'WebService::Mattermost::V4::API::Object';
with    qw(
    WebService::Mattermost::V4::API::Object::Role::BelongingToPost
    WebService::Mattermost::V4::API::Object::Role::BelongingToUser
    WebService::Mattermost::V4::API::Object::Role::CreatedAt
);

################################################################################

has emoji_name => (is => 'ro', isa => Maybe[Str],                      lazy => 1, builder => 1);
has emoji      => (is => 'ro', isa => Maybe[InstanceOf[view 'Emoji']], lazy => 1, builder => 1);

################################################################################

sub _build_emoji_name { shift->raw_data->{emoji_name} }

sub _build_emoji {
    my $self = shift;

    return unless $self->emoji_name;
    return $self->api->emoji->get_by_name($self->emoji_name)->item;
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::Reaction

=head1 DESCRIPTION

Details a Mattermost reaction object.

=head2 ATTRIBUTES

=over 4

=item C<emoji_name>

The name of the emoji attached to the post.

=item C<emoji>

Related C<WebService::Mattermost::V4::API::Object::Emoji> object.

=back

=head1 SEE ALSO

=over 4

=item C<WebService::Mattermost::V4::API::Object::Role::BelongingToPost>

=item C<WebService::Mattermost::V4::API::Object::Role::BelongingToUser>

=item C<WebService::Mattermost::V4::API::Object::Role::CreatedAt>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

