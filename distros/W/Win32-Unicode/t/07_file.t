use strict;
use warnings;
use utf8;
use lib 't/lib';
use Test::More;
use Test::Exception;
use Test::Win32::Unicode::Util;

use Win32::Unicode qw/:all/;

subtest file_type => sub {
    my $dir = 't/07_files';
    my $cmd = 'attrib';
    
    ok file_type(d => $dir), "$dir is dir";
    ok file_type(f => "$dir/file.txt"), "$dir/file.txt is file";
    ok file_type(d => "$dir/dir"), "$dir/dir is dir";
    
    ok file_type(e => $dir), "$dir exists";
    ok file_type(e => "$dir/file.txt"), "$dir/file.txt exists";
    ok file_type(e => "$dir/dir"), "$dir/dir exists";
    
    subtest hidden => sub {
        system $cmd, '+H', "$dir/hidden.txt" and die "Oops!!";
        system $cmd, '+H', "$dir/hidden" and die "Oops!!";
        ok file_type(hf => "$dir/hidden.txt"), "hidden file";
        ok file_type(hd => "$dir/hidden"), "hidden dir";
        
        done_testing;
    };
    
    subtest readonly => sub {
        system $cmd, '+R', "$dir/read_only.txt" and die "Oops!!";
        system $cmd, '+R', "$dir/read_only" and die "Oops!!";
        ok file_type(rf => "$dir/read_only.txt"), "read only file";
        ok file_type(rd => "$dir/read_only"), "read only dir";
        
        done_testing;
    };
    
    is file_size("$dir/10byte.txt"), 10;
    ok not file_size("$dir");
    ok not file_type(t => '');
    is slurp("$dir/10byte.txt"), '1234567890';
    
    done_testing;
};

subtest simple => sub {
    my $tmpdir = tempdir( CLEANUP => 1 ) or die $!;
    my $filename = '森鷗外';
    
    ok touchW "$tmpdir/$filename";
    ok copyW "$tmpdir/$filename", "$tmpdir/$filename.txt";
    ok unlinkW "$tmpdir/$filename";
    ok moveW "$tmpdir/$filename.txt", "$tmpdir/$filename";
    ok renameW "$tmpdir/$filename", "$tmpdir/$filename.txt";
    ok unlinkW "$tmpdir/$filename.txt";
    
    done_testing;
};

subtest '$_' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 ) or die $!;
    local $_ = "$tmpdir/ほげ";
    ok touchW;
    ok unlinkW;
    
    done_testing;
};

subtest 'stat' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 ) or die $!;
    my $file = "$tmpdir/test";
    touchW $file;
    
    my @stat = CORE::stat $file;
    
    my $fh = Win32::Unicode::File->new(r => $file) or die $!;
    for my $data (
        +{ file => $file, desc => 'filename' },
        +{ file => $fh, desc => 'filehandle' }
    ) {
        subtest $data->{desc} => sub {
            my @statW = statW $data->{file};
            
            is $statW[0],  $stat[0],  'dev';
            TODO : {
                local $TODO = 'CYGWIN' if CYGWIN;
                is $statW[1],  $stat[1],  'ino';
                is $statW[2],  $stat[2],  'mode';
            }
            is $statW[3],  $stat[3],  'nlink';
            is $statW[4],  $stat[4],  'uid';
            is $statW[5],  $stat[5],  'gid';
            is $statW[6],  $stat[6],  'rdev';
            is $statW[7],  $stat[7],  'size';
            is $statW[8],  $stat[8],  'atime';
            is $statW[9],  $stat[9],  'mtime';
            is $statW[10], $stat[10], 'ctime';
            is $statW[11], $stat[11], 'blksize';
            is $statW[12], $stat[12], 'blocks';
            
            my $statW = statW $data->{file};
            
            is $statW->{dev},     $stat[0],  'dev';
            TODO : {
                local $TODO = 'CYGWIN' if CYGWIN;
                is $statW->{ino},     $stat[1],  'ino';
                is $statW->{mode},    $stat[2],  'mode';
            }
            is $statW->{nlink},   $stat[3],  'nlink';
            is $statW->{uid},     $stat[4],  'uid';
            is $statW->{gid},     $stat[5],  'gid';
            is $statW->{rdev},    $stat[6],  'rdev';
            is $statW->{size},    $stat[7],  'size';
            is $statW->{atime},   $stat[8],  'atime';
            is $statW->{mtime},   $stat[9],  'mtime';
            is $statW->{ctime},   $stat[10], 'ctime';
            is $statW->{blksize}, $stat[11], 'blksize';
            is $statW->{blocks},  $stat[12], 'blocks';
            
            done_testing;
        };
    }
    
    done_testing;
};

subtest 'stat on dir' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 ) or die $!;
    my @stat = CORE::stat $tmpdir;
    
    my $dh = Win32::Unicode::Dir->new->open($tmpdir) or die $!;
    for my $data (
        +{ dir => $tmpdir, desc => 'dirname' },
        +{ dir => $dh, desc => 'dirhandle' }
    ) {
        subtest $data->{desc} => sub {
            my @statW = statW $data->{dir};
            
            is $statW[0],  $stat[0],  'dev';
            TODO : {
                local $TODO = 'CYGWIN' if CYGWIN;
                is $statW[1],  $stat[1],  'ino';
                is $statW[2],  $stat[2],  'mode';
            }
            is $statW[3],  $stat[3],  'nlink';
            is $statW[4],  $stat[4],  'uid';
            is $statW[5],  $stat[5],  'gid';
            is $statW[6],  $stat[6],  'rdev';
            is $statW[7],  $stat[7],  'size';
            is $statW[8],  $stat[8],  'atime';
            is $statW[9],  $stat[9],  'mtime';
            is $statW[10], $stat[10], 'ctime';
            is $statW[11], $stat[11], 'blksize';
            is $statW[12], $stat[12], 'blocks';
            
            my $statW = statW $data->{dir};
            
            is $statW->{dev},     $stat[0],  'dev';
            TODO : {
                local $TODO = 'CYGWIN' if CYGWIN;
                is $statW->{ino},     $stat[1],  'ino';
                is $statW->{mode},    $stat[2],  'mode';
            }
            is $statW->{nlink},   $stat[3],  'nlink';
            is $statW->{uid},     $stat[4],  'uid';
            is $statW->{gid},     $stat[5],  'gid';
            is $statW->{rdev},    $stat[6],  'rdev';
            is $statW->{size},    $stat[7],  'size';
            is $statW->{atime},   $stat[8],  'atime';
            is $statW->{mtime},   $stat[9],  'mtime';
            is $statW->{ctime},   $stat[10], 'ctime';
            is $statW->{blksize}, $stat[11], 'blksize';
            is $statW->{blocks},  $stat[12], 'blocks';
            
            done_testing;
        };
    }
    
    done_testing;
};

subtest utime => sub {
    my $tmpdir = tempdir( CLEANUP => 1 ) or die $!;
    my $file = "$tmpdir/test";
    touchW $file;
    my ($org_atime, $org_mtime) = (statW $file)[8, 9];
    is utimeW($org_atime - 1000, $org_mtime - 1000, $file), 1, 'utime ok';
    my ($new_atime, $new_mtime) = (statW $file)[8, 9];
    
    is $org_atime - 1000, $new_atime, 'atime ok';
    is $org_mtime - 1000, $new_mtime, 'atime ok';
};

subtest 'utime on file handle' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 ) or die $!;
    my $file = "$tmpdir/test";
    touchW $file;
    
    my $fh = Win32::Unicode::File->new(r => $file);
    
    my ($org_atime, $org_mtime) = (statW $fh)[8, 9];
    is utimeW($org_atime - 1000, $org_mtime - 1000, $fh), 1, 'utime ok';
    my ($new_atime, $new_mtime) = (statW $fh)[8, 9];
    
    is $org_atime - 1000, $new_atime, 'atime ok';
    is $org_mtime - 1000, $new_mtime, 'atime ok';
};

subtest exeption => sub {
    open STDERR, '>', File::Spec->devnull;
    dies_ok { file_type() };
    dies_ok { file_type('t') };
    dies_ok { copyW() };
    dies_ok { copyW('test') };
    dies_ok { moveW() };
    dies_ok { moveW('test') };
    dies_ok { renameW() };
    dies_ok { renameW('test') };
    
    done_testing;
};

done_testing;
