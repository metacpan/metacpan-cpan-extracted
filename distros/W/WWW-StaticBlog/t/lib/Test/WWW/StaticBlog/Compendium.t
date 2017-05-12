package Test::WWW::StaticBlog::Compendium;

use parent 'Test::Mini::TestCase';
use Test::Mini::Assertions;

use Data::Faker;
use Data::Faker::DateTime;
use Directory::Scratch;
use File::Spec;
use Text::Lorem;

use WWW::StaticBlog::Author;
use WWW::StaticBlog::Compendium;
use WWW::StaticBlog::Post;

use List::MoreUtils qw( uniq          );
use Text::Outdent   qw( outdent_quote );

sub _generate_post
{
    my %options = @_;

    my $faker = Data::Faker->new();
    my $lorem = Text::Lorem->new();

    return WWW::StaticBlog::Post->new(
        author    => $options{author}    || $faker->name(),
        posted_on => $options{posted_on} || Data::Faker::DateTime::timestr('%F %H:%M:%S'),
        tags      => $options{tags}      || $lorem->words(int(rand(3))),
        title     => $options{title}     || $lorem->sentences(1),
        raw_body  => outdent_quote(
            $options{raw_body} || $lorem->paragraphs(3)
        ),
    );
}

sub _generate_author
{
    my %options = @_;

    my $faker = Data::Faker->new();

    return WWW::StaticBlog::Author->new(
        name  => $options{name}  || $faker->name(),
        email => $options{email} || $faker->email(),
        alias => $options{alias} || $faker->username(),
    );
}

sub test_constructed_with_values
{
    my @posts = map { _generate_post() } (1..5);

    my $compendium = WWW::StaticBlog::Compendium->new(
        posts   => [ @posts   ],
    );

    assert_eq(
        [ $compendium->sorted_posts() ],
        [ sort { DateTime->compare($a->posted_on(), $b->posted_on()) } @posts ],
        'sorted_posts sorts by posted_on',
    );
}

sub test_find_posts_for_author
{
    my @posts = map { _generate_post() } (1..5);

    my $author = _generate_author(
        name => $posts[0]->author()
    );

    push @posts, _generate_post(author => $author->alias())
        for (1..3);

    my $compendium = WWW::StaticBlog::Compendium->new(
        posts   => [ @posts   ],
    );

    assert_eq(
        [ $compendium->posts_for_author($author->alias())  ],
        [ grep { $_->author() eq $author->alias() } @posts ],
        'posts_for_author finds posts with the same author string',
    );

    assert_eq(
        [ $compendium->posts_for_author($author) ],
        [
            grep {
                $_->author() eq $author->alias()
                || $_->author() eq $author->name()
            } @posts
        ],
        'posts_for_author finds posts with the same author, or alias, when given an Author',
    );
}

sub test_load_posts_from_dir
{
    my $tmpdir = Directory::Scratch->new();

    my $compendium = WWW::StaticBlog::Compendium->new(
        posts_dir => "$tmpdir",
    );
    $tmpdir->touch('post1', split("\n", outdent_quote(q|
        Author: jhelwig
        Title: foo
        Post-Date: 2010-03-25 21:19:40

        Here's the post contents.
    |)));
    $tmpdir->touch('post2', split("\n", outdent_quote(q|
        Author: jhelwig
        Title: bar
        Post-Date: 2010-03-25 21:20:00

        Here's the second post's contents.
    |)));
    $tmpdir->touch('post3', split("\n", outdent_quote(q|
        Author: Jacob Helwig
        Title: baz
        Post-Date: 2010-03-25 21:30:00

        Here's the third post's contents.
    |)));

    assert_eq(
        $compendium->num_posts(),
        3,
        'Loads 3 posts from files',
    );

    assert_eq(
        [ map { $_->raw_body() } $compendium->sorted_posts() ],
        [
            "Here's the post contents.\n",
            "Here's the second post's contents.\n",
            "Here's the third post's contents.\n",
        ],
    );

    $tmpdir->mkdir('more_posts');
    $tmpdir->touch(
        File::Spec->catdir('more_posts', 'post3'),
        split("\n", outdent_quote(q|
            Author: Jacob Helwig
            Title: qux
            Post-Date: 2010-03-25 22:00:30

            Here's the fourth post's contents.
        |))
    );

    assert($compendium->reload_posts());

    assert_eq(
        $compendium->num_posts(),
        4,
        'Loads 4 posts from files',
    );

    assert_eq(
        [ map { $_->raw_body() } $compendium->sorted_posts() ],
        [
            "Here's the post contents.\n",
            "Here's the second post's contents.\n",
            "Here's the third post's contents.\n",
            "Here's the fourth post's contents.\n",
        ],
    )
}

1;
