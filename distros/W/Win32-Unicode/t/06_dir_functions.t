use strict;
use warnings;
use utf8;
use lib 't/lib';
use Test::More;
use Test::Exception;
use Test::Win32::Unicode::Util;

use File::Spec;

use Win32::Unicode::Dir;
use Win32::Unicode::File;

subtest 'mkdir/rmdir' => sub {
    safe_dir {
        my $dirname = "I \x{2665} Perl";
        
        ok mkdirW($dirname), "mkdirW will be success";
        ok !mkdirW($dirname), "exsists directory";
        
        ok rmdirW($dirname), 'rmdir will be success';
        ok !rmdirW($dirname), 'directory not found';
    };
    
    done_testing;
};

subtest 'mkdir/rmdir using $_' => sub {
    safe_dir {
        local $_ = "I \x{2665} Perl";
        
        ok mkdirW, "mkdirW will be success";
        ok !mkdirW, "exsists directory";
        
        ok rmdirW, 'rmdir will be success';
        ok !rmdirW, 'directory not found';
    };
    
    done_testing;
};

subtest 'chdir/getcwd' => sub {
    safe_dir {
        my $cwd = shift;
        my $dirname = "I \x{2665} Perl";
        mkdirW $dirname;
        
        ok chdirW($dirname), "chdirW will be success";
        
        SKIP: {
            skip 'only MSWIN32', 1 if CYGWIN;
            is(File::Spec->catfile(getcwdW), File::Spec->catfile($cwd, $dirname), "getcwdW will be success");
        };
        
        ok chdirW('..'), 'parent directory chdir';
        rmdirW $dirname;
    };
    
    done_testing;
};

subtest 'file_list/dir_list' => sub {
    safe_dir {
        my $cwd = shift;
        my $tmpdir = 'test';
        my ($dir, $file) = ("dir_\x{2665}", "file_\x{2665}");
        
        mkdirW $tmpdir;
        mkdirW "$tmpdir/$dir";
        touchW "$tmpdir/$file";
        
        is_deeply [dir_list $tmpdir], [$dir], 'get all directorys';
        is_deeply [file_list $tmpdir], [$file], 'get all files';
        
        rmdirW "$tmpdir/$dir";
        unlinkW "$tmpdir/$file";
        rmdirW $tmpdir;
    };
    
    done_testing;
};

subtest 'exceptions' => sub {
    open STDERR, '>', File::Spec->devnull or die $!;
    dies_ok { chdirW } 'chdirW must be directory specified';
    done_testing;
};

done_testing;
