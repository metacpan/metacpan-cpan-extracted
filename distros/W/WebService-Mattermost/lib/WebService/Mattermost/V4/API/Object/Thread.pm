package WebService::Mattermost::V4::API::Object::Thread;

use Moo;
use Types::Standard qw(ArrayRef Maybe);

use WebService::Mattermost::V4::API::Object::Post;

extends 'WebService::Mattermost::V4::API::Object';

################################################################################

has [ qw(
    order
    matches
    posts
) ] => (is => 'ro', isa => Maybe[ArrayRef], lazy => 1, builder => 1);

################################################################################

sub _build_order   { shift->raw_data->{order}   }
sub _build_matches { shift->raw_data->{matches} }

sub _build_posts {
    my $self = shift;

    my @posts;

    foreach my $post (keys %{$self->raw_data->{posts}}) {
        push @posts, WebService::Mattermost::V4::API::Object::Post
            ->new($self->_related_args($self->raw_data->{posts}->{$post}));
    }

    if (scalar @posts) {
        @posts = sort { $a->create_at <=> $b->create_at } @posts;
    }

    return \@posts;
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::Thread

=head1 DESCRIPTION

Describes a list of Mattermost posts.

=head2 ATTRIBUTES

=over 4

=item C<matches>

If the posts are a search result, a list of strings that match.

=item C<order>

=item C<posts>

An arrayref of posts in the list, ordered by date created.

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

