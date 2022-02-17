#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw< lives dies >;
use Test::MockFile ();

my $euid     = $>;
my $egid     = int $);
my $filename = __FILE__;
my $file     = Test::MockFile->file( $filename, 'whatevs' );

my $is_root = $> == 0 || $) =~ /( ^ | \s ) 0 ( \s | $)/xms;
my $top_gid;
my $next_gid;

if ( !$is_root ) {
    my @groups;
    ( $top_gid, @groups ) = split /\s+/xms, $);

    # root can have $) set to "0 0"
    ($next_gid) = grep $_ != $top_gid, @groups;
}

# Three scenarios:
# 1. If you're root, switch to +9999
# 2. If you're not root, do you have another group to use?
# 3. If you're not root and have no other group, switch to -1

subtest(
    'Default ownership' => sub {
        my $dir_foo  = Test::MockFile->dir('/foo');
        my $file_bar = Test::MockFile->file( '/foo/bar', 'content' );

        ok( -d '/foo',     'Directory /foo exists' );
        ok( -f '/foo/bar', 'File /foo/bar exists' );

        foreach my $path (qw< /foo /foo/bar >) {
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
    }
);

subtest(
    'Change ownership of file to someone else' => sub {
        note("\$>: $>, \$): $)");

        my $chown_cb = sub {
            my ( $args, $message ) = @_;

            $! = 0;

            if ($is_root) {
                ok( chown( @{$args} ), $message );
                is( $! + 0, 0,  'chown succeeded' );
                is( "$!",   '', 'No failure' );
            }
            else {
                ok( !chown( @{$args} ), $message );
                is( $! + 0, 1, "chown failed (EPERM): \$>:$>, \$):$)" );
            }
        };

        $chown_cb->(
            [ $euid + 9999, $egid + 9999, $filename ],
            'chown file to some high, probably unavailable, UID/GID',
        );

        $chown_cb->(
            [ $euid, $egid + 9999, $filename ],
            'chown file to some high, probably unavailable, GID',
        );

        $chown_cb->(
            [ $euid + 9999, $egid, $filename ],
            'chown file to some high, probably unavailable, UID',
        );

        $chown_cb->(
            [ 0, 0, $filename ],
            'chown file to root',
        );

        $chown_cb->(
            [ $euid, 0, $filename ],
            'chown file to root GID',
        );

        $chown_cb->(
            [ 0, $egid, $filename ],
            'chown file to root UID',
        );
    }
);

subtest(
    'chown with bareword (nonexistent file)' => sub {
        no strict;
        my $bareword_file = Test::MockFile->file('RANDOM_FILE_THAT_WILL_NOT_EXIST');

        is( $! + 0, 0, '$! starts clean' );
        ok(
            !chown( $euid, $egid, RANDOM_FILE_THAT_WILL_NOT_EXIST ),
            'Using bareword treats it as string',
        );

        is( $! + 0, 2, 'Correct ENOENT error' );
    }
);

subtest(
    'chown only user, only group, both' => sub {
        is( $! + 0, 0, '$! starts clean' );
        ok(
            chown( $euid, -1, $filename ),
            'chown\'ing file to only UID',
        );
        is( $! + 0, 0, '$! still clean' );

        ok(
            chown( -1, $egid, $filename ),
            'chown\'ing file to only GID',
        );
        is( $! + 0, 0, '$! still clean' );

        ok(
            chown( $euid, $egid, $filename ),
            'chown\'ing file to both UID and GID',
        );
        is( $! + 0, 0, '$! still clean' );
    }
);

subtest(
    'chown to different group of same user' => sub {

        # See if this user has another group available
        # (we might be on a user that has only one group)
        $next_gid
          or skip_all('This user only has one group');

        is( $top_gid, $egid, 'Skipping the first GID' );
        isnt( $next_gid, $egid, 'Testing a different GID' );

        is( $! + 0, 0, '$! starts clean' );
        ok(
            chown( -1, $next_gid, $filename ),
            'chown\'ing file to a different GID',
        );
        is( $! + 0, 0, '$! stays clean' );
    }
);

subtest(
    'chown on typeglob / filehandle' => sub {
        my $filename = '/tmp/not-a-file';
        my $file     = Test::MockFile->file($filename);

        open my $fh, '>', $filename
          or die;

        print {$fh} "whatevs\n"
          or die;

        my ( $exp_euid, $exp_egid ) = $is_root ? ( $euid + 9999, $egid + 9999 ) : ( $euid, $egid );

        if ($is_root) {
            is( $! + 0,                             0, '$! starts clean' );
            is( chown( $exp_euid, $exp_egid, $fh ), 1, 'root chown on a file handle works' );
            is( $! + 0,                             0, '$! stays clean' );
        }
        else {
            is( $! + 0,                             0, '$! starts clean' );
            is( chown( $exp_euid, $exp_egid, $fh ), 1, 'Non-root chown on a file handle works' );
            is( $! + 0,                             0, '$! stays clean' );
        }

        close $fh
          or die;

        my (
            $dev,   $ino,   $mode,  $nlink,   $uid, $gid, $rdev, $size,
            $atime, $mtime, $ctime, $blksize, $blocks
        ) = stat($filename);

        is( $uid, $exp_euid, "Owner of the file is now there" );
        is( $gid, $exp_egid, "Group of the file is now there" );
    }
);

subtest(
    'chown does not reset $!' => sub {
        my $file = Test::MockFile->file( '/foo' => 'bar' );

        $! = 3;
        is( $! + 0, 3, '$! is set to 3 for our test' );
        ok( chown( -1, -1, '/foo' ), 'Successfully run chown' );
        is( $! + 0, 3, '$! is still 3 (not reset by chown)' );
    }
);

done_testing();
exit;
