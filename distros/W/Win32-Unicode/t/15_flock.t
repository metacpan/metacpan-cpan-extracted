use strict;
use warnings;
use Test::More;
use Test::Exception;

use Win32::Unicode;
use utf8;
use File::Temp qw/tempdir/;

subtest read => sub {
    my $tmpdir = tempdir CLEANUP => 1;
    
    touchW "$tmpdir/read" or die $!;
    my $fh = Win32::Unicode::File->new;
    $fh->open(r => "$tmpdir/read") or die $!;
    
    ok $fh->flock(1);
    ok $fh->unlock;
    ok $fh->flock(2);
    ok $fh->unlock;
    ok $fh->flock(5);
    ok $fh->unlock;
    ok $fh->flock(6);
    ok $fh->flock(8);
    
    $fh->close;
    
    done_testing;
};

subtest write => sub {
    my $tmpdir = tempdir CLEANUP => 1;
    
    touchW "$tmpdir/write" or die $!;
    my $fh = Win32::Unicode::File->new;
    $fh->open(w => "$tmpdir/write") or die $!;
    
    ok $fh->flock(1);
    ok $fh->unlock;
    ok $fh->flock(2);
    ok $fh->unlock;
    ok $fh->flock(5);
    ok $fh->unlock;
    ok $fh->flock(6);
    ok $fh->flock(8);
    
    $fh->close;
    
    done_testing;
};

done_testing;
