use strict;
use warnings;
use utf8;
use Test::More 0.96;
use Test::Exception;

use JSON::MaybeXS ();
use Path::Tiny qw(path);
use YAML::Tiny ();

use Test::TempFile;

subtest 'new creates an empty file' => sub {
    my $t = Test::TempFile->new;
    my $path = $t->path;

    ok( $path, 'path is set' );
    ok( -e $path, 'file was created' );
    is( path($path)->slurp, '', 'file is empty' );

    ok( $t->absolute, 'absolute path is set' );
    is( path($t->absolute)->absolute, $t->absolute, 'path is absolute' );
    is( path($t->absolute)->basename, path($path)->basename, 'basename is correct' );

    path($path)->spew_utf8('test');
    is( path($t->absolute)->slurp_utf8, 'test', 'absolute points to same file' );

    undef $t;
    ok( !-e $path, 'file cleaned up when object destroyed' );
};

subtest 'can edit the tempfile' => sub {
    my $t = Test::TempFile->new;
    is( $t->set_content('Foo'), $t, 'set_content() returns self' );
    is( path($t->path)->slurp_utf8, 'Foo', 'content updated on disk' );

    $t->set_content('日本');
    is( path($t->path)->slurp_utf8, '日本', 'content updated on disk (UTF-8)' );

    is( $t->append_content("\nBar"), $t, 'append_content() returns self' );
    is( path($t->path)->slurp_utf8, "日本\nBar", 'content appended on disk' );

    $t->append_content("💩");
    is( path($t->path)->slurp_utf8, "日本\nBar💩", 'content appended (UTF-8)' );

    ok( $t->unlink, 'unlink successful' );
    ok( !-e $t->path, 'file removed on disk' );
};

subtest 'can get a filehandle for the tempfile' => sub {
    my $t = Test::TempFile->new;
    my $fh = $t->filehandle('>');
    print {$fh} "sausages\n";
    close $fh;

    is( path($t->path)->slurp_utf8, "sausages\n", 'filehandle points to correct file' );

    $fh = $t->filehandle('>');
    print {$fh} "🌭\n";
    close $fh;
    is( path($t->path)->slurp_utf8, "🌭\n", 'filehandle supports UTF-8' );

    $fh = $t->filehandle();
    print {$fh} "d\n";
    close $fh;
    is( path($t->path)->slurp_utf8, "d\n", 'defaults to write handle' );

    $fh = $t->filehandle('<');
    throws_ok {
        no warnings;
        print {$fh} "sausages\n" or die $!;
    } qr/Bad file descriptor/, 'filehandle has correct mode';
    my $line = <$fh>;
    is( $line, "d\n", 'read handle works' );

    $fh = $t->filehandle('>>');
    print {$fh} "e\n";
    close $fh;
    is( path($t->path)->slurp_utf8, "d\ne\n", 'append handle works' );
};

subtest 'can access file content' => sub {
    my $t = Test::TempFile->new;
    path($t->path)->spew("foo");
    is( $t->content, "foo", 'content reads file correctly' );

    path($t->path)->spew_utf8("こんにちは");
    is( $t->content, "こんにちは", 'content reads UTF-8 content' );
};

subtest 'can check if file exists or is empty' => sub {
    my $t = Test::TempFile->new;
    ok( $t->exists, 'exists at start' );
    ok( $t->empty, 'empty at start' );

    unlink $t->path;
    ok( !$t->exists, "doesn't exist after unlink" );
    ok( $t->empty, 'empty after unlink' );

    path($t->path)->touch;
    ok( $t->exists, 'after touch' );
    ok( $t->empty, 'still empty' );

    path($t->path)->spew_utf8("hello");
    ok( !$t->empty, 'not empty anymore' );
};

subtest 'can be created with content' => sub {
    my $t = Test::TempFile->new("testing");
    is(path($t->path)->slurp_utf8, "testing", 'file created with content' );

    $t = Test::TempFile->new(["a", "b"]);
    is(path($t->path)->slurp_utf8, "ab", 'file created from arrayref' );

    $t = Test::TempFile->to_json({ a => [1,2] });
    my $content = path($t->path)->slurp_utf8;
    is_deeply( JSON::MaybeXS->new(utf8 => 1)->decode($content), { a => [1,2] },
        'created as a JSON file' );

    $t = Test::TempFile->to_yaml({ a => [1,2] });
    is_deeply( YAML::Tiny->read($t->path)->[0], { a => [1,2] },
        'created as a YAML file' );
};

subtest 'can decode YAML/JSON content' => sub {
    my $t = Test::TempFile->new;
    path($t->path)->spew_utf8('{ "a": [1, 2] }');
    is_deeply( $t->from_json, { a => [1,2] }, 'decoded JSON' );

    $t = Test::TempFile->new;
    path($t->path)->spew_utf8("a:\n - 1\n - 2");
    is_deeply( $t->from_yaml, { a => [1,2] }, 'decoded YAML' );
};

done_testing;
