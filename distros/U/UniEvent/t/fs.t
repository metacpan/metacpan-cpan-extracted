use 5.012;
use lib 't/lib';
use MyTest;
use UniEvent::Fs;
use UniEvent::Error;

catch_run('[fs]');

BEGIN { *Fs:: = *UniEvent::Fs:: }

my $vdir  = var("");
my $file  = var("file");
my $file2 = var("file2");
my $dir   = var("dir");
my $l     = UE::Loop->default;
my ($expected, $happened);
my $success = sub { ok !$_[0]; $happened++ };
my $fail    = sub { ok $_[0]; $happened++ };
my $async_mode;

{
    no warnings;
    sub subtest ($&) {
        my ($name, $sub) = @_;
        MyTest::subtest($name, sub {
            Fs::mkpath($vdir) unless -d $vdir;
            $happened = 0;
            $expected = 1;
            
            $sub->();
    
            if ($async_mode && defined $expected) {
                $l->run();
                is $happened, $expected;
                $expected = undef;
            }
            
            UniEvent::Fs::remove_all($vdir) if -d $vdir;
        });
    }
}

subtest 'constants' => sub {
    foreach my $name (qw/
        DEFAULT_FILE_MODE
        DEFAULT_DIR_MODE
        
        OPEN_APPEND
        OPEN_CREAT
        OPEN_DIRECT
        OPEN_DIRECTORY
        OPEN_DSYNC
        OPEN_EXCL
        OPEN_EXLOCK
        OPEN_NOATIME
        OPEN_NOCTTY
        OPEN_NOFOLLOW
        OPEN_NONBLOCK
        OPEN_RANDOM
        OPEN_RDONLY
        OPEN_RDWR
        OPEN_SEQUENTIAL
        OPEN_SHORT_LIVED
        OPEN_SYMLINK
        OPEN_SYNC
        OPEN_TEMPORARY
        OPEN_TRUNC
        OPEN_WRONLY

        SYMLINK_DIR
        SYMLINK_JUNCTION

        COPYFILE_EXCL
        COPYFILE_FICLONE
        COPYFILE_FICLONE_FORCE

        FTYPE_BLOCK
        FTYPE_CHAR
        FTYPE_DIR
        FTYPE_FIFO
        FTYPE_LINK
        FTYPE_FILE
        FTYPE_SOCKET
        FTYPE_UNKNOWN
        
        STAT_DEV
        STAT_INO
        STAT_MODE
        STAT_NLINK
        STAT_UID
        STAT_GID
        STAT_RDEV
        STAT_SIZE
        STAT_ATIME
        STAT_MTIME
        STAT_CTIME
        STAT_BLKSIZE
        STAT_BLOCKS
        STAT_FLAGS
        STAT_GEN
        STAT_BIRTHTIME
        STAT_TYPE
        STAT_PERMS        
    /) {
        ok(defined eval("$name"), "$name");
    }
};

subtest 'xs-sync' => sub {
    subtest 'mkdir' => sub {
        subtest 'non-existant' => sub {
            ok Fs::mkdir($dir);
            ok Fs::isdir($dir);
        };
        subtest 'dir exists' => sub {
            Fs::mkdir($dir);
            my ($ok, $err) = Fs::mkdir($dir);
            ok !$ok;
            is $err, UE::SystemError::file_exists;
        };
    };
    
    subtest "rmdir" => sub {
        subtest "non-existant" => sub {
            my (undef, $err) = Fs::rmdir($dir);
            is $err, UniEvent::SystemError::no_such_file_or_directory;
        };
        subtest "dir exists" => sub {
            Fs::mkdir($dir);
            ok Fs::rmdir($dir);
            ok !Fs::isdir($dir);
        };
    };

    subtest "mkpath" => sub {
        ok Fs::mkpath(var("dir2/dir3////dir4"));
        ok Fs::isdir(var("dir2/dir3/dir4"));
    };

    subtest "scandir" => sub {
        subtest "empty dir" => sub {
            my $ret = Fs::scandir($vdir);
            cmp_deeply $ret, [];
        };
        subtest "dir" => sub {
            Fs::mkdir(var("adir"));
            Fs::mkdir(var("bdir"));
            Fs::touch(var("afile"));
            Fs::touch(var("bfile"));
            my $ret = Fs::scandir($vdir);
            cmp_deeply $ret, [
                ["adir",  FTYPE_DIR],
                ["afile", FTYPE_FILE],
                ["bdir",  FTYPE_DIR],
                ["bfile", FTYPE_FILE],
            ];
        };
    };

    subtest "remove" => sub {
        subtest "non-existant" => sub {
            ok !Fs::remove($file);
            dies_ok { Fs::remove($file) };
        };
        subtest "file" => sub {
            Fs::touch($file);
            ok Fs::remove($file);
            ok !Fs::exists($file);
        };
    };

    subtest "remove_all" => sub {
        Fs::mkpath(var("dir/dir1/dir2/dir3"));
        Fs::mkpath(var("dir/dir4"));
        Fs::touch(var("dir/file1"));
        Fs::touch(var("dir/file2"));
        Fs::touch(var("dir/dir4/file3"));
        Fs::touch(var("dir/dir1/file4"));
        Fs::touch(var("dir/dir1/dir2/file5"));
        Fs::touch(var("dir/dir1/dir2/dir3/file6"));
        ok Fs::remove_all(var("dir"));
        ok !Fs::exists(var("dir"));
    };
    
    subtest "open/close" => sub {
        subtest "non-existant no-create" => sub {
            my ($fd, $err) = Fs::open($file, OPEN_RDONLY);
            ok !$fd;
            is $err, UE::SystemError::no_such_file_or_directory;
        };
        subtest "non-existant create" => sub {
            my $fd = Fs::open($file, OPEN_RDWR | OPEN_CREAT);
            ok $fd;
            ok Fs::close($fd);
        };
        subtest "existant" => sub {
            Fs::touch($file);
            my $fd = Fs::open($file, OPEN_RDONLY);
            ok $fd;
            Fs::close($fd);
        };
    };

    subtest "stat" => sub {
        subtest "non-existant" => sub {
            dies_ok { Fs::stat($file) };
        };
        subtest "path" => sub {
            Fs::touch($file);
            my $s = Fs::stat($file);
            cmp_ok $s->[STAT_MTIME], '>', 0;
            is $s->[STAT_TYPE], FTYPE_FILE;
        };
        subtest "fd" => sub {
            Fs::touch($file);
            my $fd = Fs::open($file, OPEN_RDONLY);
            my $s = Fs::stat($fd);
            is $s->[STAT_TYPE], FTYPE_FILE;
            Fs::close($fd);
        };
    };

    subtest "exists/isfile/isdir" => sub {
        ok !Fs::exists($file);
        ok !Fs::isfile($file);
        ok !Fs::isdir($file);
        Fs::touch($file);
        ok Fs::exists($file);
        ok Fs::isfile($file);
        ok !Fs::isdir($file);
        Fs::mkdir($dir);
        ok Fs::exists($dir);
        ok !Fs::isfile($dir);
        ok Fs::isdir($dir);
    };

    subtest "access" => sub {
        ok !Fs::access($file);
        ok !Fs::access($file, 4);
        Fs::touch($file);
        ok Fs::access($file);
        ok Fs::access($file, 6);
        unless (win32()) {
            ok !Fs::access($file, 1);
            ok !Fs::access($file, 7);
        }
    };

    subtest "unlink" => sub {
        Fs::touch($file);
        ok Fs::unlink($file);
        ok !Fs::exists($file);
    };

    subtest "read/write" => sub {
        my $fd = Fs::open($file, OPEN_RDWR | OPEN_CREAT);
        my $s = Fs::read($fd, 100);
        is $s, "";

        ok Fs::write($fd, "hello ");
        ok Fs::write($fd, "world");

        $s = Fs::read($fd, 100, 0);
        is $s, "hello world";

        Fs::write($fd, ["d", "u", "d", "e"], 6);
        Fs::close($fd);

        is Fs::stat($file)->[STAT_SIZE], 11;

        $fd = Fs::open($file, OPEN_RDONLY);
        is Fs::read($fd, 11), "hello duded";
        Fs::close($fd);
    };

    subtest "truncate" => sub {
        my $fd = Fs::open($file, OPEN_RDWR | OPEN_CREAT);
        Fs::write($fd, "0123456789");
        Fs::close($fd);
        is Fs::stat($file)->[STAT_SIZE], 10;

        $fd = Fs::open($file, OPEN_RDWR);
        Fs::truncate($fd, 5);
        Fs::close($fd);
        is Fs::stat($file)->[STAT_SIZE], 5;

        Fs::truncate($file);
        is Fs::stat($file)->[STAT_SIZE], 0;
    };

    subtest "chmod" => sub {
        subtest "path" => sub {
            Fs::touch($file, 0644);
            Fs::chmod($file, 0666);
            is Fs::stat($file)->[STAT_PERMS], 0666;
        };
        subtest "fd" => sub {
            Fs::touch($file, 0644);
            my $fd = Fs::open($file, OPEN_RDONLY);
            Fs::chmod($fd, 0600);
            is Fs::stat($fd)->[STAT_PERMS], 0600;
            Fs::close($fd);
        };
    } unless win32();

    subtest "touch" => sub {
        subtest "non-existant" => sub {
            ok Fs::touch($file);
            ok Fs::isfile($file);
        };
        subtest "exists" => sub {
            ok Fs::touch($file);
            my $s = Fs::stat($file);
            my $mtime = $s->[STAT_MTIME];
            my $atime = $s->[STAT_ATIME];
            select undef, undef, undef, 0.001;
            ok Fs::touch($file);
            ok Fs::isfile($file);
            $s = Fs::stat($file);
            cmp_ok $s->[STAT_MTIME], '>', $mtime;
            cmp_ok $s->[STAT_ATIME], '>', $atime;
        };
    };

    subtest "utime" => sub {
        subtest "path" => sub {
            Fs::touch($file);
            ok Fs::utime($file, 1000, 1000);
            is Fs::stat($file)->[STAT_ATIME], 1000;
            is Fs::stat($file)->[STAT_MTIME], 1000;
        };
        subtest "fd" => sub {
            Fs::touch($file);
            my $fd = Fs::open($file, OPEN_RDONLY);
            ok Fs::utime($fd, 2000, 2000);
            Fs::close($fd);
            is Fs::stat($file)->[STAT_ATIME], 2000;
            is Fs::stat($file)->[STAT_MTIME], 2000;
        } unless win32();
    };

    #no tests for chown

    subtest "rename" => sub {
        Fs::touch($file);
        ok Fs::rename($file, $file2);
        ok Fs::isfile($file2);
        ok !Fs::exists($file);
    };
};

######################### ASYNC ###############################
subtest 'xs-async' => sub {
    $async_mode = 1;
    
    subtest "mkdir" => sub {
        subtest "ok" => sub {
            Fs::mkdir($dir, 0755, $success, $l);
            $l->run();
            ok Fs::isdir($dir);
        };
        subtest "err" => sub {
            Fs::mkdir($dir);
            Fs::mkdir($dir, 0755, sub {
                $happened++;
                is $_[0], UniEvent::SystemError::file_exists;
            });
        };
    };

    subtest "rmdir" => sub {
        Fs::mkdir($dir);
        Fs::rmdir($dir, $success, $l);
        $l->run();
        ok !Fs::exists($dir);
    };

    subtest "mkpath" => sub {
        Fs::mkpath(var("dir2/dir3////dir4"), 0755, $success, $l);
        $l->run();
        ok Fs::isdir(var("dir2"));
        ok Fs::isdir(var("dir2/dir3"));
        ok Fs::isdir(var("dir2/dir3/dir4"));
    };

    subtest "scandir" => sub {
        Fs::mkdir(var("adir"));
        Fs::mkdir(var("bdir"));
        Fs::touch(var("afile"));
        Fs::touch(var("bfile"));
        Fs::scandir(var(""), sub {
            my ($list, $err) = @_;
            $happened++;
            ok !$err;
            cmp_deeply $list, [
                ["adir",  FTYPE_DIR],
                ["afile", FTYPE_FILE],
                ["bdir",  FTYPE_DIR],
                ["bfile", FTYPE_FILE],
            ];
        });
    };

    subtest "remove" => sub {
        Fs::touch($file);
        Fs::remove($file, $success, $l);
        $l->run();
        ok !Fs::exists($file);
    };

    subtest "remove_all" => sub {
        Fs::mkpath(var("dir/dir1/dir2/dir3"));
        Fs::mkpath(var("dir/dir4"));
        Fs::touch(var("dir/file1"));
        Fs::touch(var("dir/file2"));
        Fs::touch(var("dir/dir4/file3"));
        Fs::touch(var("dir/dir1/file4"));
        Fs::touch(var("dir/dir1/dir2/file5"));
        Fs::touch(var("dir/dir1/dir2/dir3/file6"));
        Fs::remove_all($dir, $success, $l);
        $l->run();
        ok !Fs::exists($dir);
    };

    subtest "open/close" => sub {
        $expected = 2;
        Fs::open($file, OPEN_RDWR | OPEN_CREAT, 0644, sub {
            my ($fd, $err) = @_;
            $happened++;
            ok !$err;
            ok $fd;
            Fs::close($fd, $success);
        });
    };

    subtest "stat" => sub {
        my $cb = sub {
            my ($stat, $err) = @_;
            ok !$err;
            cmp_ok $stat->[STAT_MTIME], '>', 0;
            is $stat->[STAT_TYPE], FTYPE_FILE;
            $happened++;
        };
        subtest "path" => sub {
            Fs::touch($file);
            Fs::stat($file, $cb);
        };
        subtest "fd" => sub {
            Fs::touch($file);
            my $fd = Fs::open($file, OPEN_RDONLY);
            Fs::stat($fd, $cb);
            $l->run;
            Fs::close($fd);
        };
    };

    subtest "exists/isfile/isdir" => sub {
        $expected = 9;
        my $yes = sub {
            my ($val, $err) = @_;
            ok !$err;
            ok $val;
            $happened++;
        };
        my $no = sub {
            my ($val, $err) = @_;
            ok !$err;
            ok !$val;
            $happened++;
        };

        Fs::exists($file, $no);
        Fs::isfile($file, $no);
        Fs::isdir($file, $no);
        $l->run();

        Fs::touch($file);

        Fs::exists($file, $yes);
        Fs::isfile($file, $yes);
        Fs::isdir($file, $no);
        $l->run();

        Fs::mkdir($dir);

        Fs::exists($dir, $yes);
        Fs::isfile($dir, $no);
        Fs::isdir($dir, $yes);
        $l->run();
    };

    subtest "access" => sub {
        $expected = win32() ? 4 : 6;
        Fs::access($file, 0, $fail);
        $l->run();
        Fs::access($file, 4, $fail);
        $l->run();
        Fs::touch($file);
        Fs::access($file, 0, $success);
        $l->run();
        Fs::access($file, 6, $success);
        $l->run();
        unless (win32()) {
            Fs::access($file, 1, $fail);
            $l->run();
            Fs::access($file, 7, $fail);
            $l->run();
        }
    };

    subtest "unlink" => sub {
        Fs::touch($file);
        Fs::unlink($file, $success);
        $l->run();
        ok !Fs::exists($file);
    };

    subtest "read/write" => sub {
        $expected = 6;
        my $fd = Fs::open($file, OPEN_RDWR | OPEN_CREAT);
        Fs::read($fd, 100, 0, sub {
            my ($s, $err) = @_;
            $happened++;
            ok !$err;
            is $s, "";
        });
        $l->run();

        Fs::write($fd, "hello ", -1, $success);
        $l->run();
        Fs::write($fd, "world", -1, $success);
        $l->run();

        Fs::read($fd, 100, 0, sub {
            my ($s, $err) = @_;
            $happened++;
            ok !$err;
            is $s, "hello world";
        });
        $l->run();

        Fs::write($fd, ["d", "u", "d", "e"], 6, $success);
        $l->run();

        Fs::close($fd);

        is Fs::stat($file)->[STAT_SIZE], 11;

        $fd = Fs::open($file, OPEN_RDONLY);
        Fs::read($fd, 11, 0, sub {
            my ($s, $err) = @_;
            $happened++;
            ok !$err;
            is $s, "hello duded";
        });
        $l->run();
        Fs::close($fd);
    };

    subtest "truncate" => sub {
        $expected = 2;
        my $fd = Fs::open($file, OPEN_RDWR | OPEN_CREAT);
        Fs::write($fd, "0123456789");
        Fs::close($fd);
        is Fs::stat($file)->[STAT_SIZE], 10;

        $fd = Fs::open($file, OPEN_RDWR);
        Fs::truncate($fd, 5, $success);
        $l->run();
        Fs::close($fd);
        is Fs::stat($file)->[STAT_SIZE], 5;

        Fs::truncate($file, 0, $success);
        $l->run();
        is Fs::stat($file)->[STAT_SIZE], 0;
    };

    subtest "chmod" => sub {
        subtest "path" => sub {
            Fs::touch($file, 0644);
            Fs::chmod($file, 0666, $success);
            $l->run();
            is Fs::stat($file)->[STAT_PERMS], 0666;
        };
        subtest "fd" => sub {
            Fs::touch($file, 0644);
            my $fd = Fs::open($file, OPEN_RDONLY);
            Fs::chmod($fd, 0600, $success);
            $l->run();
            is Fs::stat($file)->[STAT_PERMS], 0600;
            Fs::close($fd);
        };
    } unless win32();

    subtest "touch" => sub {
        $expected = 2;
        Fs::touch($file, 0644, $success);
        $l->run();
        my $s = Fs::stat($file);
        my $mtime = $s->[STAT_MTIME];
        my $atime = $s->[STAT_ATIME];
        select undef, undef, undef, 0.001;

        Fs::touch($file, 0644, $success);
        $l->run();
        ok Fs::isfile($file);
        $s = Fs::stat($file);
        cmp_ok $s->[STAT_MTIME], '>', $mtime;
        cmp_ok $s->[STAT_ATIME], '>', $atime;
    };

    subtest "utime" => sub {
        subtest "path" => sub {
            Fs::touch($file);
            Fs::utime($file, 1000, 1100, $success);
            $l->run();
            is Fs::stat($file)->[STAT_ATIME], 1000;
            is Fs::stat($file)->[STAT_MTIME], 1100;
        };
        subtest "fd" => sub {
            Fs::touch($file);
            my $fd = Fs::open($file, OPEN_RDONLY);
            Fs::utime($fd, 2000, 2100, $success);
            $l->run();
            Fs::close($fd);
            is Fs::stat($file)->[STAT_ATIME], 2000;
            is Fs::stat($file)->[STAT_MTIME], 2100;
        } unless win32();
    };

    # no tests for chown

    subtest "rename" => sub {
        Fs::touch($file);
        Fs::rename($file, $file2, $success);
        $l->run();
        ok !Fs::exists($file);
        ok Fs::isfile($file2);
    };
};

done_testing();
