package WebService::Mattermost::V4::API::Object::Role::BelongingToPost;

use Moo::Role;
use Types::Standard qw(Maybe InstanceOf Str);

use WebService::Mattermost::Helper::Alias 'view';

################################################################################

has post_id => (is => 'ro', isa => Maybe[Str],                     lazy => 1, builder => 1);
has post    => (is => 'ro', isa => Maybe[InstanceOf[view 'Post']], lazy => 1, builder => 1);

################################################################################

sub _build_post_id { shift->raw_data->{post_id} }

sub _build_post {
    # TODO
    return undef;
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::Role::BelongingToPost

=head1 DESCRIPTION

Link a view object to a post.

=head2 ATTRIBUTES

=over 4

=item C<post_id>

The post's ID.

=item C<post>

Linked C<WebService::Mattermost::V4::API::Object::Post> object.

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

