use 5.010;

use MooseX::Declare;

class WWW::StaticBlog::Site
    with WWW::StaticBlog::Role::FileLoader
    with MooseX::SimpleConfig
    with MooseX::Getopt
{
    our $VERSION = '0.02';

    use Cwd                   qw( getcwd                );
    use File::Copy::Recursive qw( rcopy                 );
    use File::Slurp           qw( write_file            );
    use List::PowerSet        qw( powerset              );
    use WWW::StaticBlog::Util qw( sanitize_for_dir_name );

    use File::Path qw(
        make_path
        remove_tree
    );
    use List::MoreUtils qw(
        any
        uniq
    );
    use Time::SoFar qw(
        runinterval
        runtime
    );

    use DateTime ();
    use File::Spec ();
    use Set::Object ();
    use WWW::StaticBlog::Author ();
    use WWW::StaticBlog::Compendium ();
    use WWW::StaticBlog::Tag ();
    use XML::Atom::SimpleFeed ();

    has title => (
        is       => 'rw',
        isa      => 'Str',
        required => 1,
    );

    has tagline => (
        is        => 'rw',
        isa       => 'Str',
        predicate => 'has_tagline',
    );

    has authors => (
        is      => 'rw',
        isa     => 'ArrayRef[WWW::StaticBlog::Author]|Undef',
        lazy    => 1,
        builder => '_build_authors',
        traits  => [qw(
            Array
            MooseX::Getopt::Meta::Attribute::Trait::NoGetopt
        )],
        handles => {
            add_authors    => 'push',
            all_authors    => 'elements',
            clear_authors  => 'clear',
            filter_authors => 'grep',
            num_authors    => 'count',
            sorted_authors => 'sort',
        },
    );

    has compendium => (
        is      => 'rw',
        isa     => 'WWW::StaticBlog::Compendium',
        lazy    => 1,
        builder => '_build_compendium',
        traits  => [qw(
            MooseX::Getopt::Meta::Attribute::Trait::NoGetopt
        )],
    );

    has posts_dir => (
        is        => 'rw',
        isa       => 'Str',
        predicate => 'has_posts_dir',
    );

    has authors_dir => (
        is        => 'rw',
        isa       => 'Str',
        predicate => 'has_authors_dir',
    );

    has static_dir => (
        is        => 'rw',
        isa       => 'Str',
        predicate => 'has_static_dir',
    );

    has output_dir => (
        is      => 'rw',
        isa     => 'Str',
        default => sub { getcwd() },
    );

    has template_class => (
        is      => 'ro',
        isa     => 'Str',
        default => '::Template::Toolkit',
    );

    has _template => (
        is         => 'ro',
        isa        => 'Object',
        lazy_build => 1,
    );

    has template_options => (
        is      => 'rw',
        traits  => ['Hash'],
        isa     => 'HashRef',
        lazy    => 1,
        default => sub { {} },
        handles => {
            delete_template_option  => 'delete',
            get_template_option     => 'get',
            has_no_template_options => 'is_empty',
            set_template_option     => 'set',
            template_option_pairs   => 'kv',
        },
    );

    has index_template => (
        is       => 'rw',
        isa      => 'Str',
        required => 1,
    );

    has index_post_count => (
        is      => 'rw',
        isa     => 'Int',
        default => 10,
    );

    has post_template => (
        is       => 'rw',
        isa      => 'Str',
        required => 1,
    );

    has author_template => (
        is  => 'rw',
        isa => 'Str',
    );

    has tag_template => (
        is  => 'rw',
        isa => 'Str',
    );

    has debug => (
        is      => 'rw',
        isa     => 'Bool',
        default => 0,
    );

    has post_feed => (
        is  => 'rw',
        isa => 'Str|Undef',
    );

    has post_feed_count => (
        is      => 'rw',
        isa     => 'Int',
        default => 10,
    );

    has recent_posts_count => (
        is      => 'rw',
        isa     => 'Int',
        default => 15,
    );

    has url => (
        is      => 'rw',
        isa     => 'Str',
        lazy    => 1,
        default => sub {
            my $self = shift;
            die "url required with post_feed"
                if $self->post_feed();
            return '';
        },
    );

    method _build_authors()
    {
        return [] unless $self->has_authors_dir();

        my @authors;
        foreach my $author_file ($self->_find_files_for_dir($self->authors_dir())) {
            push @authors, WWW::StaticBlog::Author->new(filename => $author_file);
        }

        return \@authors;
    }

    method _build_compendium()
    {
        return WWW::StaticBlog::Compendium->new(
            posts_dir => $self->posts_dir(),
        );
    }

    method reload_authors()
    {
        $self->clear_authors();
        $self->authors($self->_build_authors());
    }

    method _build__template()
    {
        my $template_class = $self->template_class();
        $template_class =~ s/^::/WWW::StaticBlog::/;

        Class::MOP::load_class($template_class);

        $template_class->new(
            options  => $self->template_options(),
            fixtures => {
                debug        => $self->debug(),
                site_tagline => $self->tagline(),
                site_title   => $self->title(),
                tags         => [
                    $self->compendium()->all_tags(),
                ],
                recent_posts => [
                    $self->compendium()->newest_n_posts($self->recent_posts_count()),
                ],
            },
        );
    }

    method render_posts()
    {
        say "Rendering posts:";
        foreach my $post ($self->compendium()->sorted_posts()) {
            runinterval();
            print "\t" . $post->title();
            my @path = split('/', $post->url());
            my $out_file = File::Spec->catfile(
                $self->output_dir(),
                @path,
            );

            my @extra_head_sections;
            push @extra_head_sections, {
                name     => 'style',
                attr     => 'type="text/css"',
                contents => $post->inline_css(),
            } if $post->inline_css();

            $self->_template()->render_to_file(
                $self->post_template(),
                {
                    post                => $post,
                    page_title          => $post->title(),
                    extra_head_sections => \@extra_head_sections,
                },
                $out_file,
            );
            say " => $out_file (" . runinterval() . ")";
        }
    }

    method render_index()
    {
        runinterval();
        print "Rendering index... ";

        my @posts = $self->compendium()->newest_n_posts($self->index_post_count());
        my @extra_post_head_sections = $self->_unique_head_sections_for_posts(@posts);

        my $out_file = File::Spec->catfile(
            $self->output_dir(),
            'index.html',
        );
        $self->_template()->render_to_file(
            $self->index_template(),
            {
                posts               => [ @posts                    ],
                extra_head_sections => [ @extra_post_head_sections ],
            },
            $out_file,
        );

        say "(" . runinterval() . ")";
    }

    method _unique_head_sections_for_posts(@posts)
    {
        my @extra_style_head_sections;
        foreach my $post (@posts) {
            push @extra_style_head_sections, $post->inline_css()
                if $post->inline_css();
        }

        return map +{
                name     => 'style',
                attr     => 'type="text/css"',
                contents => $_,
        }, uniq @extra_style_head_sections;
    }

    method render_post_feed()
    {
        return unless $self->post_feed();
        runinterval();
        print "Generating post feed... ";

        my $feed = XML::Atom::SimpleFeed->new(
            title     => $self->title(),
            subtitle  => $self->tagline(),
            updated   => DateTime->now()->iso8601(),
            generator => 'WWW::StaticBlog',
            link      => $self->url(),
            link      => {
                rel  => 'self',
                href => $self->url() . $self->post_feed(),
            },
        );

        foreach my $post ($self->compendium()->newest_n_posts($self->post_feed_count())) {
            $feed->add_entry(
                title     => $post->title(),
                link      => $self->url() . $post->url(),
                id        => $self->url() . $post->url(),
                author    => $post->author(),
                content   => $post->body(),
                published => $post->posted_on(),
                updated   => $post->updated_on(),
                (map {
                    (category => $_->name())
                } ($post->sorted_tags())),
            );
        }

        my $out_file = File::Spec->catfile(
            $self->output_dir(),
            $self->post_feed(),
        );

        my (undef, $out_dir, undef) = File::Spec->splitpath($out_file);
        die "Could not create $out_dir"
            unless make_path($out_dir);

        write_file(
            $out_file,
            $feed->as_string(),
        );

        say $self->post_feed() . " (" . runinterval() . ")";
    }

    method render_tags()
    {
        runinterval();
        print "Finding unique tag combinations with posts...";
        my @all_tags = $self->compendium()->all_tags();

        my @tag_sets = map {
            [ $_->all_tags() ]
        } $self->compendium()->all_posts();

        push(
            @tag_sets,
            grep { scalar @{$_} }
            map {
                @{powerset(@$_)}
            } @tag_sets
        );
        push @tag_sets, map {[$_]} @all_tags;

        @tag_sets = do {
            use Data::Dumper;
            my %seen;
            map { $_->[0] }
            grep { !$seen{$_->[1]}++ }
            map { [ $_, Dumper($_) ] }
            @tag_sets
        };

        @tag_sets = uniq(@tag_sets);
        say " (" . runinterval() . ")";

        my $all_tags = Set::Object->new();
        $all_tags->insert(@all_tags);
        while (my $tag_set = shift @tag_sets) {
            my $tag_page = $self->_partial_url_for_tag_set(@$tag_set);
            my @posts    = $self->compendium()->posts_for_tags(@$tag_set);

            say "\t$tag_page";
            say "\t\tFound @{[ scalar @posts ]} post(s) (" . runinterval() . ")";

            print "\t\tRendering...";

            my $other_tags = $all_tags - Set::Object->new()->insert(@$tag_set);
            $self->_render_tags_for_set_and_posts(
                $tag_page,
                $tag_set,
                \@posts,
                [$other_tags->members()],
            );

            say " done (" . runinterval() . ")";
        }

    }

    method _render_tags_for_set_and_posts($tag_page, $tag_set, $posts, $other_tags)
    {
        my @plus_tags;
        my %additional_tags_with_posts = $self->_other_tags_with_posts($tag_set, $other_tags);
        foreach my $tag (sort keys %additional_tags_with_posts) {
            push(
                @plus_tags,
                {
                    name  => $tag,
                    count => $additional_tags_with_posts{$tag},
                    link  => $self->_url_for_tag_set(
                        @$tag_set,
                        WWW::StaticBlog::Tag->new($tag),
                    ),
                },
            );
        }

        my %minus_tags;
        foreach my $tag (@$tag_set) {
            my $new_tagset = Set::Object->new();
            $new_tagset->insert(@$tag_set);
            $new_tagset->remove($tag);
            next unless $new_tagset->members();

            $minus_tags{$tag->name()} = $self->_url_for_tag_set($new_tagset->members());
        }

        $self->_template()->render_to_file(
            $self->tag_template(),
            {
                posts               => $posts,
                extra_head_sections => [$self->_unique_head_sections_for_posts(@$posts)],
                tags                => $tag_set,
                minus               => \%minus_tags,
                plus                => \@plus_tags,
            },
            File::Spec->catfile(
                $self->output_dir(),
                'tags',
                $tag_page,
            ),
        );
    }

    method _other_tags_with_posts($current_tags, $other_tags)
    {
        my %tags_with_posts;
        foreach my $tag (@$other_tags) {
            next if any { $tag eq $_ } @$current_tags;

            my $post_count = $self->compendium()->posts_for_tags(@$current_tags, $tag);
            next unless $post_count;

            $tags_with_posts{$tag->name()} = $post_count;
        }
        return %tags_with_posts;
    }

    method _url_for_tag_set(@tags)
    {
        return '/tags/' . $self->_partial_url_for_tag_set(@tags);
    }

    method _partial_url_for_tag_set(@tags)
    {
            my $tag_page = join(
                '/',
                sort map {sanitize_for_dir_name($_->name())} @tags
            ) . '/index.html';
    }

    method render_archives()
    {
        say "Rendering archive pages...";

        my $archive;
        print "\t$archive ";
    }

    method copy_static_files()
    {
        return unless $self->has_static_dir();

        runinterval();
        print "Copying static files... ";
        rcopy($self->static_dir(), $self->output_dir());
        say "(" . runinterval() . ")";
    }

    method run()
    {
        say "Enabling debug mode." if $self->debug();
        say "Cleaning up... " . $self->output_dir();
        remove_tree( $self->output_dir(), {keep_root => 1} );

        $self->render_posts();
        $self->render_index();
        $self->render_post_feed();
        $self->render_tags();
#        $self->render_archives();
        $self->copy_static_files();

        runinterval();
        print "Saving post data... ";
        $_->save() for $self->compendium()->all_posts();
        say "(" . runinterval() . ")";

        say "Total time: " . runtime();
    }
}

__END__

=head1 NAME

WWW::StaticBlog::Site - A WWW::StaticBlog site.

=head1 VERSION

0.02

=head1 SYNOPSIS

A WWW::StaticBlog site.

=head1 AUTHOR

Jacob Helwig, C<< <jhelwig at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-staticblog at rt.cpan.org>,
or through the web interface at
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
