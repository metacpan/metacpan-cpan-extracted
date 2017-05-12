package WWW::StaticBlog::Compendium;

our $VERSION = '0.02';

use 5.010;
use Moose;
use MooseX::Method::Signatures;

with 'WWW::StaticBlog::Role::FileLoader';

use MooseX::Types::Moose qw(
    ArrayRef
    Undef
);

use List::MoreUtils qw(any);

use DateTime ();
use Set::Object ();
use WWW::StaticBlog::Post ();
use WWW::StaticBlog::Tag ();

has posts => (
    is      => 'rw',
    traits  => ['Array'],
    isa     => 'ArrayRef[WWW::StaticBlog::Post]|Undef',
    lazy    => 1,
    builder => '_build_posts',
    handles => {
        add_post      => 'push',
        all_posts     => 'elements',
        clear_posts   => 'clear',
        filter_posts  => 'grep',
        num_posts     => 'count',
        _sorted_posts => 'sort',
    },
);

has posts_dir => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'have_posts_dir',
    clearer   => 'forget_posts_dir',
);

sub BUILD
{
    my $self = shift;

    $WWW::StaticBlog::Tag::compendium = $self;
}

method sorted_posts()
{
    return $self->_sorted_posts(
        sub {
            DateTime->compare(
                $_[0]->posted_on(),
                $_[1]->posted_on(),
            )
        }
    );
}

method _sort_posts_by_date_descending(@posts)
{
    # TODO: Figure out why this doesn't work as "return sort ..."
    my @sorted_posts = sort {
        DateTime->compare(
            $b->posted_on(),
            $a->posted_on(),
        )
    } @posts;

    return @sorted_posts;
}

method newest_n_posts($n)
{
    my @posts = $self->_sort_posts_by_date_descending(
        $self->all_posts()
    );

    return grep { defined } @posts[0..$n];
}

method posts_for_author($author)
{
    return $self->_posts_for_author_obj($author)
        if (ref $author eq 'WWW::StaticBlog::Author');

    return $self->_posts_for_author_str($author);
}

method _posts_for_author_obj($author)
{
    return $self->filter_posts(
        sub {
            $_->author() =~ $author->name()
            || $_->author() =~ $author->alias()
        }
    );
}

method _posts_for_author_str($author)
{
    return $self->filter_posts(
        sub { $_->author() =~ $author }
    );
}

method _build_posts()
{
    return [] unless $self->have_posts_dir();

    my @posts;
    foreach my $post_file ($self->_find_files_for_dir($self->posts_dir())) {
        push @posts, WWW::StaticBlog::Post->new(filename => $post_file);
    }

    return \@posts;
}

method reload_posts()
{
    $self->clear_posts();
    $self->posts($self->_build_posts());
}

method all_tags()
{
    my $set = Set::Object->new();

    foreach my $post ($self->all_posts()) {
        $set->insert($post->all_tags());
    }

    return sort { $a->name() cmp $b->name() } $set->members();
}

method posts_for_tags(@tags)
{
    my @posts = $self->all_posts();
    foreach my $tag (@tags) {
        @posts = $self->_filter_posts_to_tag($tag, @posts);
        return unless @posts;
    }

    return $self->_sort_posts_by_date_descending(@posts);
}

method _filter_posts_to_tag($tag, @posts)
{
    my $tag_name = ref($tag) ? $tag->name() : $tag;
    return grep {
        any {
            $_->name() =~ m/$tag_name/;
        } $_->all_tags();
    } @posts;
}

"I don't think there's a punch-line scheduled, is there?";
__END__

=head1 NAME

WWW::StaticBlog::Compendium - Collection of all Authors, and Posts for a blog.

=head1 VERSION

0.02

=head1 SYNOPSIS

Collection of all Authors, and Posts for a blog.

=head1 AUTHOR

Jacob Helwig, C<< <jhelwig at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-staticblog at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-StaticBlog>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.
    perldoc WWW::StaticBlog
You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-StaticBlog>


=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-StaticBlog>


=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-StaticBlog>


=item * Search CPAN

L<http://search.cpan.org/dist/WWW-StaticBlog>


=back


=head1 COPYRIGHT & LICENSE

Copyright 2010 Jacob Helwig, all rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
