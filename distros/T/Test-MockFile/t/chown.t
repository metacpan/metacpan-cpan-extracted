#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw< lives dies >;
use Test::MockFile qw< strict >;

my $euid     = $>;
my $egid     = int $);
my $filename = __FILE__;
my $file     = Test::MockFile->file( $filename, 'whatevs' );

subtest( 'Defaults' => sub {
    my $dir_foo  = Test::MockFile->dir('/foo');
    my $file_bar = Test::MockFile->file( '/foo/bar', 'content' );

    ok( -d '/foo',    'Directory /foo exists' );
    ok( -f '/foo/bar', 'File /foo/bar exists' );

    foreach my $path ( qw< /foo /foo/bar > ) {
        is(
            ( stat $path )[4],
            $euid,
            "$path set UID correctly to $euid",
        );

        is(
            ( stat $path )[5],
            $egid,
            "$path set GID correctly to $egid",
        );
    }
});

subtest( 'Change ownership of file to someone else fails' => sub {
    ok(
        !chown(  $euid + 9999, $egid + 9999, $filename ),
        'Cannot chown file to some high, probably unavailable, UID/GID',
    );

    is( "$!", 'Operation not permitted', 'Correct error string' );
    is( $!+0, 1, 'Correct error code for EPERM' );

    $! = 0;

    ok(
        !chown(  $euid, $egid + 9999, $filename ),
        'Cannot chown file to some high, probably unavailable, GID',
    );

    is( "$!", 'Operation not permitted', 'Correct error string' );
    is( $!+0, 1, 'Correct error code for EPERM' );

    $! = 0;

    ok(
        !chown(  $euid + 9999, $egid, $filename ),
        'Cannot chown file to some high, probably unavailable, UID',
    );

    is( "$!", 'Operation not permitted', 'Correct error string' );
    is( $!+0, 1, 'Correct error code for EPERM' );

    SKIP: {
        note( "\$>: $>, int \$): " . int $) );
        $> == 0 || grep /(^ | \s ) 0 ( \s | $)/xms, $)
            and skip( 'Running as root cannot test failing to chown to root' => 9 );

        $! = 0;

        ok(
            !chown(  0, 0, $filename ),
            'Cannot chown file to root',
        );

        is( "$!", 'Operation not permitted', 'Correct error string' );
        is( $!+0, 1, 'Correct error code for EPERM' );

        $! = 0;

        is(
            chown(  $euid, 0, $filename ),
            0,
            'Cannot chown file to root GID',
        );

        is( "$!", 'Operation not permitted', 'Correct error string' );
        is( $!+0, 1, 'Correct error code for EPERM' );

        $! = 0;

        is(
            chown(  0, $egid, $filename ),
            0,
            'Cannot chown file to root UID',
        );

        is( "$!", 'Operation not permitted', 'Correct error string' );
        is( $!+0, 1, 'Correct error code for EPERM' );
    }
});

subtest( 'chown only user, only group, both' => sub {
    ok(
        chown(  $euid, -1, $filename ),
        'chown\'ing file to only UID',
    );

    ok(
        chown(  -1, $egid, $filename ),
        'chown\'ing file to only GID',
    );

    ok(
        chown(  $euid, $egid, $filename ),
        'chown\'ing file to both UID and GID',
    );

});

subtest( 'chown with bareword' => sub {
    no strict;
    my $bareword_file = Test::MockFile->file('RANDOM_FILE_THAT_WILL_NOT_EXIST');
    ok(
        !chown( $euid, $egid, RANDOM_FILE_THAT_WILL_NOT_EXIST),
        'Using bareword treats it as string',
    );

    is( "$!", 'No such file or directory', 'Correct error string' );
    is( $!+0, 2, 'Correct ENOENT error' );
});

subtest( 'chown to different group of same user' => sub {
    # See if this user has another group available
    # (we might be on a user that has only one group)
    my ( $top_gid, @groups ) = split /\s+/xms, $);

    # root can have $) set to "0 0"
    my ($next_gid) = grep $_ != $top_gid, @groups;
    $next_gid
        or skip_all('This user only has one group');

    is( $top_gid, $egid, 'Skipping the first GID' );
    isnt( $next_gid, $egid, 'Testing a different GID' );

    ok(
        chown(  -1, $next_gid, $filename ),
        'chown\'ing file to a different GID',
    );
});

done_testing();
exit;
