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
            'Cannot do TMF->dir( "/etc", [@content] )',
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

done_testing();
