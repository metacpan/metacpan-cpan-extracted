#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw< lives dies >;
use Test::MockFile;

sub test_content_with_keywords {
    my ( $dirname, $dir_content ) = @_;

    my $dh;
    my $open;
    ok(
        lives( sub { $open = opendir $dh, $dirname } ),
        "opendir() $dirname successful",
    );

    $open or return;

    my @content;
    ok(
        lives( sub { @content = readdir($dh) } ),
        "readdir() on $dirname successful",
    );

    is(
        \@content,
        $dir_content,
        'Correct directory content through Perl core keywords',
    );

    ok(
        lives( sub { closedir $dh } ),
        "closedir() on $dirname successful",
    );
}

my $count       = 0;
my $get_dirname = sub {
    $count++;
    return "/foo$count";
};

subtest(
    '->dir() checks' => sub {
        like(
            dies( sub { Test::MockFile->dir( '/etc', [ 'foo', 'bar' ], { 1 => 2 } ) } ),
            qr!^\QYou cannot set stats for nonexistent dir '/etc'\E!xms,
            'Cannot do TMF->dir( "/etc", [@content], { 1 => 2 } )',
        );

        like(
            dies( sub { Test::MockFile->dir( '/etc', [ 'foo', 'bar' ] ) } ),
            qr!^\QYou cannot set stats for nonexistent dir '/etc'\E!xms,
            'Cannot do TMF->dir( "/etc", [@content] )',
        );
    }
);

subtest(
    'Scenario 1: ->dir() does not create dir, keywords do' => sub {
        my $dirname = $get_dirname->();
        my $dir     = Test::MockFile->dir($dirname);

        ok( !-d $dirname,    "Directory $dirname does not exist yet" );
        ok( mkdir($dirname), "Directory $dirname got created" );
        ok( -d $dirname,     "Directory $dirname now exists" );

        is(
            $dir->contents(),
            [qw< . .. >],
            'Correct contents of directory through ->contents()',
        );

        test_content_with_keywords( $dirname, [qw< . .. >] );
    }
);

subtest(
    'Scenario 2: ->dir() on an already existing dir fails made with ->dir()' => sub {
        my $dirname = $get_dirname->();
        my $file    = Test::MockFile->file( "$dirname/bar", 'my content' );
        my $dir     = Test::MockFile->dir($dirname);

        ok( -d $dirname,      "-d $dirname succeeds, dir exists" );
        ok( !mkdir($dirname), "mkdir $dirname fails, dir already exists" );

        test_content_with_keywords( $dirname, [qw< . .. bar >] );
    }
);

subtest(
    'Scneario 3: Undef files with ->file() do not create dirs, adding content changes dir' => sub {
        my $dirname = $get_dirname->();
        my $dir     = Test::MockFile->dir($dirname);

        ok( !-d $dirname, "-d $dirname fails, does not exist yet" );

        my $file = Test::MockFile->file("$dirname/foo");

        ok( !-d $dirname,    "-d $dirname still fails after mocking file with no content" );
        ok( mkdir($dirname), "mkdir $dirname works" );
        ok( -d $dirname,     "-d $dirname now succeeds" );

        is(
            $dir->contents(),
            [qw< . .. >],
            "Correct contents to $dirname",
        );

        test_content_with_keywords( $dirname, [qw< . .. >] );

        ok( !-e "$dirname/foo", "$dirname/foo does not exist, even if $dirname does" );
        $file->contents("hello");
        ok( -e "$dirname/foo", "After file->contents(), $dirname/foo exists" );

        is(
            $dir->contents(),
            [qw< . .. foo >],
            "Correct updated contents to $dirname",
        );

        test_content_with_keywords( $dirname, [qw< . .. foo >] );
    }
);

subtest(
    'Scenario 4: Creating ->file() with content creates dir' => sub {
        my $dirname = $get_dirname->();
        my $dir     = Test::MockFile->dir($dirname);

        ok( !-d $dirname, "$dirname does not exist yet" );
        my $file = Test::MockFile->file( "$dirname/foo", 'some content' );
        ok( -d $dirname,      "$dirname now exists, after creating file with content" );
        ok( !mkdir($dirname), "mkdir $dirname fails, since dir already exists" );

        is(
            $dir->contents(),
            [qw< . .. foo >],
            "Correct contents to $dirname",
        );

        test_content_with_keywords( $dirname, [qw< . .. foo >] );
    }
);

subtest(
    'Scenario 5: Non-existent dir placeholders excluded from contents' => sub {
        my $dirname = $get_dirname->();
        my $dir     = Test::MockFile->new_dir($dirname);

        # Create a real file and a non-existent dir placeholder as children
        my $file         = Test::MockFile->file( "$dirname/real_file", 'content' );
        my $nonexist_dir = Test::MockFile->dir("$dirname/phantom_dir");

        # The non-existent dir placeholder should NOT appear in contents
        is(
            $dir->contents(),
            [qw< . .. real_file >],
            "Non-existent dir placeholder excluded from contents()",
        );

        test_content_with_keywords( $dirname, [qw< . .. real_file >] );

        # Once the dir placeholder becomes real, it should appear
        my $real_subdir = Test::MockFile->new_dir("$dirname/real_subdir");
        is(
            $dir->contents(),
            [qw< . .. real_file real_subdir >],
            "Existing subdirectory included in contents()",
        );
    }
);

subtest(
    'Scenario 6: Non-existent file mock before dir() does not make dir exist' => sub {
        my $dirname = $get_dirname->();

        # Create a non-existent file mock BEFORE the dir mock
        my $file = Test::MockFile->file("$dirname/phantom");

        # The dir should not appear to exist — the child is just a placeholder
        my $dir = Test::MockFile->dir($dirname);
        ok( !-d $dirname, "dir does not exist when only child is a non-existent file mock" );

        # mkdir still works to bring it into existence
        ok( mkdir($dirname), "mkdir succeeds on the placeholder dir" );
        ok( -d $dirname,     "dir exists after mkdir" );
    }
);

subtest(
    'Scenario 7: Existing file before dir() makes dir exist (regression)' => sub {
        my $dirname = $get_dirname->();

        # Create an existing file mock BEFORE the dir mock
        my $file = Test::MockFile->file( "$dirname/real", 'content' );

        # dir() should detect the existing child and set has_content
        my $dir = Test::MockFile->dir($dirname);
        ok( -d $dirname, "dir exists when child file has content" );

        is(
            $dir->contents(),
            [qw< . .. real >],
            "Correct contents with existing child file",
        );
    }
);

done_testing();
