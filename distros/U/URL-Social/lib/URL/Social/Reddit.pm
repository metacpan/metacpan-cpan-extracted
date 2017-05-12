package URL::Social::Reddit;
use Moose;
use namespace::autoclean;

extends 'URL::Social::BASE';

use URL::Social::Reddit::Post;

=head1 NAME

URL::Social::Reddit - Interface to the Reddit API.

=head1 DESCRIPTION

Do not use this module directly. Access it from L<URL::Social> instead.
Note, however, that this module behaves a bit different than the others.

A post on reddit can be a duplicate and/or it can end up in different
subreddits.

    use URL::Social;

    my $social = URL::Social->new(
        url => '...',
    );

    print $social->reddit->upvote_count . "\n"; # Sum of all posts' upvotes

    # ...or...

    foreach my $post ( @{$social->reddit->posts} ) {
        print $post->upvote_count . "\n";
    }

See L<URL::Social::Reddit::Post> for an overview of the data you can access
for each post.

=head1 METHODS

=cut

has 'data'  => ( isa => 'Maybe[HashRef]', is => 'ro', lazy_build => 1 );
has 'posts' => (
    traits  => [ 'Array' ],
    isa     => 'ArrayRef[URL::Social::Reddit::Post]',
    is      => 'ro',
    default => sub { [] },
    handles => {
        all_posts => 'elements',
        add_post  => 'push',
    },
);

has 'some_count'     => ( isa => 'HashRef[Int]', is => 'ro', lazy_build => 1 );
has 'upvote_count'   => ( isa => 'Int',          is => 'ro', lazy_build => 1 );
has 'downvote_count' => ( isa => 'Int',          is => 'ro', lazy_build => 1 );
has 'comment_count'  => ( isa => 'Int',          is => 'ro', lazy_build => 1 );

sub _build_data {
    my $self = shift;

    my $url = 'http://www.reddit.com/api/info.json?url=' . $self->url;

    if ( my $json = $self->get_url_json($url) ) {
        if ( my $data = $json->{data} ) {
            if ( my $children = $data->{children} ) {
                foreach my $c ( @{$children} ) {
                    $c = $c->{data};

                    my $post = URL::Social::Reddit::Post->new(
                        author         => $c->{author},
                        created        => $c->{created},
                        created_utc    => $c->{created_utc},
                        domain         => $c->{domain},
                        upvote_count   => $c->{ups},
                        downvote_count => $c->{downs},
                        comment_count  => $c->{num_comments},
                        score          => $c->{score},
                        subreddit      => $c->{subreddit},
                        permalink      => $c->{permalink},
                        title          => $c->{title},
                    );

                    $self->add_post( $post );
                }
            }
            return $data;
        }
        else {
            return undef;
        }
    }
    else {
        return undef;
    }
}

sub _build_some_count {
    my $self = shift;

    $self->_build_data;

    my %counts = (
        upvote   => 0,
        downvote => 0,
        comment  => 0,
    );

    foreach my $post ( @{$self->posts} ) {
        $counts{upvote}   += $post->upvote_count;
        $counts{downvote} += $post->downvote_count;
        $counts{comment}  += $post->comment_count;
    }

    return \%counts;
}

=head2 upvote_count

Returns the number of upvotes the post has received.

=cut

sub _build_upvote_count {
    return shift->some_count->{upvote};
}

=head2 downvote_count

Returns the number of downvotes the post has received.

=cut

sub _build_downvote_count {
    return shift->some_count->{downvote};
}

=head2 comment_count

Returns the number of comments the post has received.

=cut

sub _build_comment_count {
    return shift->some_count->{comment};
}

#
# The End
#
__PACKAGE__->meta->make_immutable;

1;

=head1 LICENSE AND COPYRIGHT

Copyright 2013-2014 Tore Aursand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.