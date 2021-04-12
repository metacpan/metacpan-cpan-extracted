use 5.012;
use warnings;
use lib 't/lib'; use MyTest;
use UniEvent::Fs;
use UniEvent::FsEvent;

BEGIN { *Fs:: = *UniEvent::Fs:: }

plan skip_all => "FsEvent support on current system is limited so no tests will run" if !linux();
plan skip_all => "skipped due to \$ENV{UNIEVENT_TEST_SKIP_FSEVENT}" if $ENV{UNIEVENT_TEST_SKIP_FSEVENT};

# TODO: check WATCH_ENTRY / STAT / RECURSIVE flags behaviour when they become working in libuv

my $l = UniEvent::Loop->default_loop;
my $file  = var 'file';
my $file2 = var 'file2';
my $dir   = var 'dir';
my $dir2  = var 'dir2';
my $call_cnt = 0;

sub cr (;$) {
    my $path = shift;
    my $ret = UniEvent::FsEvent->new($l);
    $ret->start($path) if $path;
    return $ret;
}

subtest 'constants' => sub {
    cmp_ok(RECURSIVE + RENAME + CHANGE, '>', 0, "constants exist");
};

subtest 'file tracking' => sub {
    subtest 'doesnt track non-existant files dies' => sub {
        my $h = cr;
        $h->callback(sub { die });
        dies_ok { $h->start($file) }  "exception when tries to handle non-existant file";
        $l->run();
    };
    subtest 'doesnt track non-existant files' => sub {
        my $h = cr;
        $h->callback(sub { die });
        my ($flag, $err) = $h->start($file);
        ok(!$flag, "return value is correct");
        is($err->code, UE::SystemError::ENOENT, "error code is correct");
        $l->run();
    };
    subtest 'mtime' => sub {
        Fs::touch($file);
        my $h = cr;
        $h->start($file);
        is($h->path, $file, "path getter works");
        $h->callback(cb(CHANGE, 'file', "file mtime"));
        my $t = UE::Timer->once(0.001, sub { Fs::touch($file) });
        $l->run;
        check_call_cnt(1);
        Fs::unlink($file);
    };
    subtest 'contents' => sub {
        Fs::touch($file);
        my $h = UE::FsEvent->create($file, 0, cb(CHANGE, 'file', "file content"));
        my $t = UE::Timer->once(0.001, sub { fchange($file) });
        $l->run;
        check_call_cnt(1);
        Fs::unlink($file);
    };
    subtest 'rename' => sub {
        Fs::touch($file);
        my $h = UE::fs_event $file, 0, cb(RENAME, 'file', "file rename");
        my $t = UE::Timer->once(0.001, sub { Fs::rename($file, $file2) });
        $l->run;
        check_call_cnt(1);
        
        $h->callback(cb(CHANGE, 'file', "renamed file content"));
        $t = UE::Timer->once(0.001, sub { fchange($file2) });
        $l->run;
        check_call_cnt(1);
        
        Fs::unlink($file2);
    };
    foreach my $meth ('stop' ,'reset', 'clear') {
        subtest $meth => sub {
            Fs::touch($file);
            my $h = cr $file;
            $h->callback(sub {die});
            $h->$meth;
            $l->run;
            
            $h->callback(sub { $l->stop });
            $h->start($file);
            Fs::touch($file);
            $l->run;
            
            $h->$meth;
            $h->callback(sub {die});
            $l->run;
            
            pass("$meth ok");
            Fs::unlink($file);
        };
    }
    subtest 'remove' => sub {
        Fs::touch($file);
        my $h = cr $file;
        # libuv somewhy calls callback 3 times, first with status CHANGE, then 2 times with status RENAME
        $h->callback(cb(undef, 'file', "renamed file remove"));
        my $t = UE::Timer->once(0.001, sub { Fs::unlink($file) });
        $l->run;
        ok($call_cnt >= 1);
        $call_cnt = 0;
    };
};

subtest 'dir tracking' => sub {
    subtest 'doesnt track non-existant dirs' => sub {
        my $h = cr;
        my ($flag, $err) = $h->start($dir);
        ok(!$flag, "return value is correct");
        is($err->code, UE::SystemError::ENOENT, "error code is correct");
        $l->run();
    };
    subtest 'mtime' => sub {
        Fs::mkdir($dir);
        my $h = cr $dir;
        is($h->path, $dir, "path getter works");
        $h->callback(cb(CHANGE+RENAME, 'dir', "dir mtime"));
        my $t = UE::Timer->once(0.001, sub { Fs::touch($dir) });
        $l->run;
        check_call_cnt(1);
        Fs::remove_all($dir);
    };
    subtest 'contents' => sub {
        Fs::mkdir($dir);
        my $h = cr $dir;
        
        $h->callback(cb(RENAME, 'ifile', "dir content: add file"));
        my $t = UE::Timer->once(0.001, sub { Fs::touch("$dir/ifile") });
        $l->run;
        check_call_cnt(1);
        
        $h->callback(cb(RENAME, "ifile|ifile2", "dir content: rename file")); # 2 callbacks - for old remove and new create
        $t = UE::Timer->once(0.001, sub { Fs::rename("$dir/ifile", "$dir/ifile2") });
        $l->run;
        check_call_cnt(2);
        
        $h->callback(cb(RENAME, 'ifile2', "dir content: remove file"));
        $t = UE::Timer->once(0.001, sub { Fs::unlink("$dir/ifile2") });
        $l->run;
        check_call_cnt(1);
        
        Fs::remove_all($dir);
    };
    subtest 'rename' => sub {
        Fs::mkdir($dir);
        my $h = cr $dir;
        $h->callback(cb(RENAME, 'dir', "dir rename"));
        my $t = UE::Timer->once(0.001, sub { Fs::rename($dir, $dir2) });
        $l->run;
        check_call_cnt(1);
        
        # still keep tracking dir after rename
        $h->callback(cb(CHANGE+RENAME, 'dir', "renamed dir mtime"));
        $t = UE::Timer->once(0.001, sub { Fs::touch($dir2) });
        $l->run;
        check_call_cnt(1);
        $h->callback(cb(RENAME, 'ifile', "renamed dir content: add file"));
        $t = UE::Timer->once(0.001, sub { Fs::touch("$dir2/ifile") });
        $l->run;
        check_call_cnt(1);
        $h->callback(cb(RENAME, 'ifile', "renamed dir content: remove file"));
        $t = UE::Timer->once(0.001, sub { Fs::unlink("$dir2/ifile") });
        $l->run;
        check_call_cnt(1);
        
        Fs::remove_all($dir2);
    };
    subtest 'remove' => sub {
        Fs::mkdir($dir);
        my $h = cr $dir;
        $h->callback(cb(RENAME, 'dir', "renamed dir remove"));
        my $t = UE::Timer->once(0.001, sub { Fs::rmdir($dir) });
        $l->run;
        # somewhy libuv calls callback twice
        ok($call_cnt >= 1);
        $call_cnt = 0;
    };
};

done_testing();

sub cb {
    my ($check_event, $check_filename, $test_name) = @_;
    $test_name ||= '';
    return sub {
        my ($h, $filename, $events) = @_;
        is($events, $check_event, "fs callback event    is correct ($test_name)") if defined $check_event;
        like($filename, qr/^$check_filename$/, "fs callback filename is correct ($test_name)");
        $call_cnt++;
        $l->stop;
    };
}

sub fchange {
    my $file = shift;
    my $fd = Fs::open($file, OPEN_WRONLY | OPEN_APPEND);
    Fs::write($fd, rand());
    Fs::close($fd);
}

sub check_call_cnt {
    my $cnt = shift;
    is $call_cnt, $cnt, "call cnt";
    $call_cnt = 0;
}
