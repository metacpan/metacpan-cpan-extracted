package Test::WWW::StaticBlog::Site;

use parent 'Test::Mini::TestCase';
use Test::Mini::Assertions;

use Data::Faker;
use Directory::Scratch;
use File::Spec;
use Text::Lorem;

use WWW::StaticBlog::Author;
use WWW::StaticBlog::Compendium;
use WWW::StaticBlog::Post;
use WWW::StaticBlog::Site;

use List::MoreUtils qw( uniq          );
use Text::Outdent   qw( outdent_quote );

sub test_load_authors_from_dir
{
    my $tmpdir = Directory::Scratch->new();

    my $site = WWW::StaticBlog::Site->new(
        title          => 'WWW::StaticBlog',
        authors_dir    => "$tmpdir",
        index_template => 'index',
        post_template  => 'post',
    );
    $tmpdir->touch('author1.yaml', split("\n", outdent_quote(q|
        ---
        name: Jacob Helwig
        alias: jhelwig
        email: jhelwig@cpan.org
    |)));
    $tmpdir->touch('author2.yaml', split("\n", outdent_quote(q|
        ---
        name: Tom Servo
        alias: tservo
        email: tservo@satelliteoflove.com
    |)));
    $tmpdir->touch('author3.yaml', split("\n", outdent_quote(q|
        ---
        name: Crow T. Robot
        alias: crobot
        email: crobot@satelliteoflove.com
    |)));

    assert_eq(
        $site->num_authors(),
        3,
        'Loads 3 authors from files',
    );

    assert_eq(
        [
            map { $_->name() } $site->sorted_authors(
                sub { $_[0]->name() cmp $_[1]->name() }
            )
        ],
        [
            "Crow T. Robot",
            "Jacob Helwig",
            "Tom Servo",
        ],
    );

    $tmpdir->mkdir('more_authors');
    $tmpdir->touch(
        File::Spec->catdir('more_authors', 'author3.yaml'),
        split("\n", outdent_quote(q|
            ---
            name: Gypsy
            alias: gypsy
            email: gypsy@satelliteoflove.com
        |))
    );

    assert($site->reload_authors());

    assert_eq(
        $site->num_authors(),
        4,
        'Loads 4 authors from files',
    );

    assert_eq(
        [
            map { $_->name() } $site->sorted_authors(
                sub { $_[0]->name() cmp $_[1]->name() }
            )
        ],
        [
            "Crow T. Robot",
            "Gypsy",
            "Jacob Helwig",
            "Tom Servo",
        ],
    )
}

1;
