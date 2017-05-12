package Test::WWW::StaticBlog::Author;

use parent 'Test::Mini::TestCase';
use Test::Mini::Assertions;

use WWW::StaticBlog::Author;

use Test::TempDir qw( tempfile      );
use Text::Outdent qw( outdent_quote );

sub test_create_with_explicit_attributes
{
    my $author = WWW::StaticBlog::Author->new(
        name  => 'Jacob Helwig',
        email => 'jhelwig@cpan.org',
        alias => 'jhelwig',
    );

    assert_eq(
        $author->name(),
        'Jacob Helwig',
    );
    assert_eq(
        $author->email(),
        'jhelwig@cpan.org',
    );
    assert_eq(
        $author->alias(),
        'jhelwig',
    );
}

sub test_create_without_alias
{
    my $author = WWW::StaticBlog::Author->new(
        name  => 'Jacob Helwig',
        email => 'jhelwig@cpan.org',
    );

    assert_eq(
        $author->name(),
        'Jacob Helwig',
    );
    assert_eq(
        $author->email(),
        'jhelwig@cpan.org',
    );
    assert_eq(
        $author->alias(),
        undef,
    );
}

sub test_create_without_email
{
    my $author = WWW::StaticBlog::Author->new(
        name  => 'Jacob Helwig',
        alias => 'jhelwig',
    );

    assert_eq(
        $author->name(),
        'Jacob Helwig',
    );
    assert_eq(
        $author->email(),
        undef,
    );
    assert_eq(
        $author->alias(),
        'jhelwig'
    );
}

sub test_create_without_name
{
    my $author = WWW::StaticBlog::Author->new(
        email => 'jhelwig@cpan.org',
        alias => 'jhelwig',
    );

    assert_eq(
        $author->name(),
        undef,
    );
    assert_eq(
        $author->email(),
        'jhelwig@cpan.org',
    );
    assert_eq(
        $author->alias(),
        'jhelwig',
    );
}

sub test_create_from_file
{
    my ($filename) = _write_config_file(q{
        ---
        name: Jacob Helwig
        email: jhelwig@cpan.org
        alias: jhelwig
    });

    my $author = WWW::StaticBlog::Author->new(
        filename => $filename,
    );

    assert_eq(
        $author->name(),
        'Jacob Helwig',
    );
    assert_eq(
        $author->email(),
        'jhelwig@cpan.org',
    );
    assert_eq(
        $author->alias(),
        'jhelwig',
    );
}

sub test_create_from_file_without_alias
{
    my ($filename) = _write_config_file(q{
        ---
        name: Jacob Helwig
        email: jhelwig@cpan.org
    });

    my $author = WWW::StaticBlog::Author->new(
        filename => $filename,
    );

    assert_eq(
        $author->name(),
        'Jacob Helwig',
    );
    assert_eq(
        $author->email(),
        'jhelwig@cpan.org',
    );
    assert_eq(
        $author->alias(),
        undef,
    );
}

sub test_create_from_file_without_email
{
    my ($filename) = _write_config_file(q{
        ---
        name: Jacob Helwig
        alias: jhelwig
    });

    my $author = WWW::StaticBlog::Author->new(
        filename => $filename,
    );

    assert_eq(
        $author->name(),
        'Jacob Helwig',
    );
    assert_eq(
        $author->email(),
        undef,
    );
    assert_eq(
        $author->alias(),
        'jhelwig',
    );
}

sub test_create_from_file_without_name
{
    my ($filename) = _write_config_file(q{
        ---
        email: jhelwig@cpan.org
        alias: jhelwig
    });

    my $author = WWW::StaticBlog::Author->new(
        filename => $filename,
    );

    assert_eq(
        $author->name(),
        undef,
    );
    assert_eq(
        $author->email(),
        'jhelwig@cpan.org',
    );
    assert_eq(
        $author->alias(),
        'jhelwig',
    );
}

sub _write_config_file
{
    my ($contents, $suffix) = @_;
    $suffix ||= 'yaml';

    my ($config_fh, $config_filename) = tempfile(SUFFIX => ".$suffix");
    $config_fh->autoflush(1);
    print $config_fh outdent_quote($contents);

    return($config_filename, $config_fh);
}

