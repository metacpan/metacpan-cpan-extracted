use strict;
use warnings;
use utf8;
use Test::More;
use Test::Exception;

use File::Temp qw/tempdir tempfile/;
use File::Basename qw/fileparse/;
use File::Spec;

use Win32::Unicode::Dir;
use Win32::Unicode::File;

subtest 'opendir/readdir/closedir' => sub {
    my ($fh, $filename) = tempfile "tempXXXX", DIR => tempdir CLEANUP => 1 or die "$!";
    my ($name, $path) = fileparse $filename;
    
    my $wdir = new_ok 'Win32::Unicode::Dir';
    ok $wdir->open($path), 'will be open() method success';
    is $wdir->fetch, '.', "readdir: `.`";
    is $wdir->fetch, '..', "readdir: `..`";
    is $wdir->fetch, $name, "readdir: `$name`";
    ok $wdir->close, 'will be close() method success';
    
    done_testing;
};

subtest 'fetch wantarray' => sub {
    my ($fh, $filename) = tempfile "tempXXXX", DIR => tempdir CLEANUP => 1 or die "$!";
    my ($name, $path) = fileparse $filename;
    
    my $wdir = Win32::Unicode::Dir->new;
    $wdir->open($path);
    my @files = $wdir->fetch;
    is_deeply \@files, ['.', '..', $name], 'fetched all files';
    $wdir->close;
    
    done_testing;
};

subtest 'readdir the file name 0' => sub {
    my $tmpdir = tempdir CLEANUP => 1;
    touchW "$tmpdir/0";
    
    my $wdir = Win32::Unicode::Dir->new;
    $wdir->open($tmpdir);
    
    my $count;
    while (defined(my $file = $wdir->fetch)) {
        $count++;
    }
    is $count, 3, 'read successs'; # . .. 0
    
    $wdir->close;
    
    done_testing;
};

subtest 'exceptions' => sub {
    open STDERR, '>', File::Spec->devnull or die $!;
    
    dies_ok { Win32::Unicode::Dir->open()  } 'open must be filename specifiled';
    dies_ok { Win32::Unicode::Dir->fetch() } 'not blessed, cannot call fetch() method';
    dies_ok { Win32::Unicode::Dir->close() } 'not blessed, cannot call close() method';
    
    my $wdir = Win32::Unicode::Dir->new;
    dies_ok { $wdir->fetch() } 'fetch() cannot open directory handle';
    dies_ok { $wdir->close() } 'close() cannot open directory handle';
    
    done_testing;
};

done_testing;
