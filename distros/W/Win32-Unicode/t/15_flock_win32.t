use strict;
use warnings;
use Test::More;
use Test::Exception;

use Win32::Unicode;
use utf8;
use File::Temp qw/tempdir/;
use File::Spec;

plan skip_all => 'MSWin32 only' unless $^O eq 'MSWin32';

my $script_dir = 't/15_flock_win32';

subtest 'shared lock wait (flock: 1)' => sub {
    my $target = 'shared_lock_wait';
    my $tmpdir = tempdir CLEANUP => 1;
    system 'start', '/b', $^X, _script($target), $tmpdir;
    
    sleep 1;
    
    my $fh = Win32::Unicode::File->new;
    $fh->open(r => "$tmpdir/$target") or die $!;
    is $fh->readline, 'test';
    $fh->close;
    
    $fh->open(w => "$tmpdir/$target") or die $!;
    ok! $fh->write('hoge');
    $fh->flock(2);
    ok $fh->write('foo');
    $fh->close;
    
    $fh->open(r => "$tmpdir/$target") or die $!;
    is $fh->readline, 'foo';
    $fh->close;
    
    sleep 1;
    
    done_testing;
};

subtest 'exclusive lock wait (flock: 2)' => sub {
    my $target = 'ex_lock_wait';
    
    subtest 'read_lock' => sub {
        my $tmpdir = tempdir CLEANUP => 1;
        system 'start', '/b', $^X, _script($target), $tmpdir;
        
        sleep 1;
        
        my $fh = Win32::Unicode::File->new;
        $fh->open(r => "$tmpdir/$target") or die $!;
        ok! $fh->readline;
        $fh->flock(1);
        is $fh->readline, 'test';
        $fh->close;
        
        done_testing;
    };
    
    subtest 'write_lock' => sub {
        my $tmpdir = tempdir CLEANUP => 1;
        system 'start', '/b', $^X, _script($target), $tmpdir;
        
        sleep 1;
        
        my $fh = Win32::Unicode::File->new;
        $fh->open(w => "$tmpdir/$target") or die $!;
        ok! $fh->write('hoge');
        $fh->flock(2);
        ok $fh->write('foo');
        $fh->close;
        
        $fh->open(r => "$tmpdir/$target") or die $!;
        is $fh->readline, 'foo';
        $fh->close;
        
        done_testing;
    };
    
    done_testing;
};

subtest 'shared lock no wait (flock: 5)' => sub {
    my $target = 'shared_lock_no_wait';
    my $tmpdir = tempdir CLEANUP => 1;
    
    system 'start', '/b', $^X, _script($target), $tmpdir;
    
    sleep 1;
    
    my $fh = Win32::Unicode::File->new;
    $fh->open(r => "$tmpdir/$target") or die $!;
    is $fh->readline, 'test';
    $fh->close;
    
    $fh->open(w => "$tmpdir/$target") or die $!;
    ok! $fh->write('hoge');
    while(!$fh->flock(6)) {
        # noop
    }
    ok $fh->write('foo');
    $fh->close;
    
    $fh->open(r => "$tmpdir/$target") or die $!;
    is $fh->readline, 'foo';
    $fh->close;
    
    sleep 1;
    
    done_testing;
};

subtest 'exclusive lock no wait (flock: 6)' => sub {
    my $target = 'ex_lock_no_wait';
    
    subtest 'read_lock' => sub {
        my $tmpdir = tempdir CLEANUP => 1;
        system 'start', '/b', $^X, _script($target), $tmpdir;
        
        sleep 1;
        
        my $fh = Win32::Unicode::File->new;
        $fh->open(r => "$tmpdir/$target") or die $!;
        ok! $fh->readline;
        while (!$fh->flock(5)) {
            # noop
        }
        is $fh->readline, 'test';
        $fh->close;
        
        done_testing;
    };
    
    subtest 'write_lock' => sub {
        my $tmpdir = tempdir CLEANUP => 1;
        system 'start', '/b', $^X, _script($target), $tmpdir;
        
        sleep 1;
        
        my $fh = Win32::Unicode::File->new;
        $fh->open(w => "$tmpdir/$target") or die $!;
        ok! $fh->write('hoge');
        while (!$fh->flock(6)) {
            # noop
        }
        ok $fh->write('foo');
        $fh->close;
        
        $fh->open(r => "$tmpdir/$target") or die $!;
        is $fh->readline, 'foo';
        $fh->close;
        
        done_testing;
    };
    
    done_testing;
};

sub _script {
    File::Spec->catfile($script_dir, "$_[0].pl");
}

done_testing;
