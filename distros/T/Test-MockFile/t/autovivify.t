#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Errno qw/ENOENT/;

use Test::MockFile qw< nostrict >;

note "-------------- autovivify: basic file creation via open --------------";
{
    my $dir = Test::MockFile->new_dir( '/av', { 'autovivify' => 1 } );

    # File doesn't exist yet
    ok( !-e '/av/file.txt', 'auto-vivified file does not exist before open' );

    # Create and write via open
    ok( open( my $fh, '>', '/av/file.txt' ), 'open for write under autovivify dir' );
    print $fh 'hello world';
    close $fh;

    ok( -e '/av/file.txt', 'file exists after write' );
    ok( -f '/av/file.txt', 'file is a regular file' );

    # Read it back
    ok( open( my $rfh, '<', '/av/file.txt' ), 'open for read' );
    my $content = do { local $/; <$rfh> };
    close $rfh;
    is( $content, 'hello world', 'content matches what was written' );
}

note "-------------- autovivify: temp file then rename pattern --------------";
{
    my $dir = Test::MockFile->new_dir( '/tmpdir', { 'autovivify' => 1 } );

    # Write to temp file
    ok( open( my $fh, '>', '/tmpdir/.tmp.data' ), 'open temp file for write' );
    print $fh 'final content';
    close $fh;

    # Rename into place
    ok( rename( '/tmpdir/.tmp.data', '/tmpdir/data.txt' ), 'rename temp file into place' );

    # Verify final file
    ok( -e '/tmpdir/data.txt',   'renamed file exists' );
    ok( !-e '/tmpdir/.tmp.data', 'temp file no longer exists' );

    ok( open( my $rfh, '<', '/tmpdir/data.txt' ), 'can read renamed file' );
    my $content = do { local $/; <$rfh> };
    close $rfh;
    is( $content, 'final content', 'renamed file has correct content' );
}

note "-------------- autovivify: stat on non-existent file --------------";
{
    my $dir = Test::MockFile->new_dir( '/avstat', { 'autovivify' => 1 } );

    ok( !-e '/avstat/nofile', 'non-existent file under autovivify dir returns false for -e' );
    ok( !-f '/avstat/nofile', 'non-existent file returns false for -f' );
    ok( !-d '/avstat/nofile', 'non-existent file returns false for -d' );
}

note "-------------- autovivify: mkdir subdirectory --------------";
{
    my $dir = Test::MockFile->new_dir( '/avmk', { 'autovivify' => 1 } );

    ok( mkdir('/avmk/sub'),       'mkdir under autovivify dir works' );
    ok( -d '/avmk/sub',          'subdirectory exists after mkdir' );
    ok( opendir( my $dh, '/avmk' ), 'can opendir the autovivify dir' );
    my @entries = readdir($dh);
    closedir $dh;

    ok( grep( { $_ eq 'sub' } @entries ), 'subdirectory appears in readdir' );
}

note "-------------- autovivify: unlink auto-vivified file --------------";
{
    my $dir = Test::MockFile->new_dir( '/avul', { 'autovivify' => 1 } );

    ok( open( my $fh, '>', '/avul/temp' ), 'create file' );
    print $fh 'data';
    close $fh;

    ok( -e '/avul/temp',  'file exists' );
    ok( unlink('/avul/temp'), 'unlink succeeds' );
    ok( !-e '/avul/temp', 'file is gone after unlink' );
}

note "-------------- autovivify: sysopen with O_CREAT --------------";
{
    use Fcntl qw/O_WRONLY O_CREAT/;
    my $dir = Test::MockFile->new_dir( '/avsys', { 'autovivify' => 1 } );

    ok( sysopen( my $fh, '/avsys/sysfile', O_WRONLY | O_CREAT ), 'sysopen with O_CREAT under autovivify' );
    syswrite $fh, 'sysdata';
    close $fh;

    ok( -e '/avsys/sysfile', 'sysopen-created file exists' );
}

note "-------------- autovivify: cleanup on scope exit --------------";
{
    {
        my $dir = Test::MockFile->new_dir( '/avscope', { 'autovivify' => 1 } );
        ok( open( my $fh, '>', '/avscope/tmp' ), 'create file in scoped dir' );
        print $fh 'data';
        close $fh;
        ok( -e '/avscope/tmp', 'file exists in scope' );
    }

    # After scope exit, the autovivify dir and its children should be gone
    # Accessing /avscope/tmp should fall through to real FS (nostrict mode)
    ok( !-e '/avscope/tmp', 'auto-vivified file cleaned up on scope exit' );
}

note "-------------- autovivify: readdir shows created files --------------";
{
    my $dir = Test::MockFile->new_dir( '/avrd', { 'autovivify' => 1 } );

    ok( open( my $fh1, '>', '/avrd/alpha' ), 'create alpha' );
    close $fh1;
    ok( open( my $fh2, '>', '/avrd/beta' ), 'create beta' );
    close $fh2;

    ok( opendir( my $dh, '/avrd' ), 'opendir on autovivify dir' );
    my @entries = sort readdir($dh);
    closedir $dh;

    is( \@entries, [qw/. .. alpha beta/], 'readdir shows auto-vivified files' );
}

note "-------------- autovivify: glob works --------------";
{
    my $dir = Test::MockFile->new_dir( '/avgl', { 'autovivify' => 1 } );

    ok( open( my $fh1, '>', '/avgl/foo.txt' ), 'create foo.txt' );
    close $fh1;
    ok( open( my $fh2, '>', '/avgl/bar.txt' ), 'create bar.txt' );
    close $fh2;

    my @files = sort glob('/avgl/*.txt');
    is( \@files, [qw(/avgl/bar.txt /avgl/foo.txt)], 'glob finds auto-vivified files' );
}

note "-------------- autovivify: works with dir() + mkdir pattern --------------";
{
    my $dir = Test::MockFile->dir( '/avdir', { 'autovivify' => 1 } );

    # dir() creates non-existent placeholder
    ok( !-d '/avdir', 'dir with autovivify does not exist yet' );

    # mkdir materializes it
    ok( mkdir('/avdir'), 'mkdir materializes autovivify dir' );
    ok( -d '/avdir',     'dir exists after mkdir' );

    # Now auto-vivification works
    ok( open( my $fh, '>', '/avdir/newfile' ), 'open file under materialized dir' );
    print $fh 'works';
    close $fh;
    ok( -e '/avdir/newfile', 'file exists' );
}

note "-------------- autovivify: file permissions respect umask correctly --------------";
{
    # With umask 0077, perms should be 0666 & ~0077 = 0600
    # Bug: XOR (^) gives 0666 ^ 0077 = 0611 (wrong — adds execute bits)
    my $old_umask = umask(0077);

    my $dir = Test::MockFile->new_dir( '/avperms', { 'autovivify' => 1 } );

    ok( open( my $fh, '>', '/avperms/secret' ), 'create file with umask 0077' );
    print $fh 'data';
    close $fh;

    my $mode = ( stat('/avperms/secret') )[2] & 07777;
    is( sprintf( '%04o', $mode ), '0600', 'autovivified file perms are 0600 with umask 0077 (not 0611)' );

    umask($old_umask);
}

done_testing();
