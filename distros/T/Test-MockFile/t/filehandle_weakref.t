#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Errno qw/EBADF/;

use Test::MockFile qw< nostrict >;

note "-------------- FILEHANDLE AFTER MOCK DESTRUCTION --------------";
note "When a mock goes out of scope, the weakened data ref in the tied";
note "filehandle becomes undef. Operations must not crash.";

# Helper: open a mock file handle, destroy the mock, return the fh.
sub _open_then_destroy_mock {
    my ($path, $content, $mode) = @_;
    $mode //= '<';

    my $mock = Test::MockFile->file($path, $content);
    open(my $fh, $mode, $path) or die "open failed: $!";

    # Destroy the mock — weakened ref in tied handle becomes undef.
    undef $mock;

    return $fh;
}

subtest 'readline after mock destruction returns undef' => sub {
    my $fh = _open_then_destroy_mock('/fake/readline', "hello\nworld\n");

    my $line;
    my $ok = lives { $line = <$fh> };
    ok($ok, "readline does not crash after mock destruction");
    is($line, undef, "readline returns undef");

    close $fh;
};

subtest 'getc after mock destruction returns undef' => sub {
    my $fh = _open_then_destroy_mock('/fake/getc', "abc");

    my $ch;
    my $ok = lives { $ch = getc($fh) };
    ok($ok, "getc does not crash after mock destruction");
    is($ch, undef, "getc returns undef");

    close $fh;
};

subtest 'sysread after mock destruction returns 0' => sub {
    my $fh = _open_then_destroy_mock('/fake/sysread', "data");

    my ($buf, $ret, $errno) = ('');
    my $ok = lives {
        $ret = sysread($fh, $buf, 10);
        $errno = $! + 0;
    };
    ok($ok, "sysread does not crash after mock destruction");
    is($ret, 0, "sysread returns 0 bytes");
    is($errno, EBADF, "errno is EBADF after sysread on destroyed mock");

    close $fh;
};

subtest 'print after mock destruction returns false' => sub {
    my $fh = _open_then_destroy_mock('/fake/print', '', '>');

    my ($ret, $errno);
    my $ok = lives {
        $ret = print {$fh} "hello";
        $errno = $! + 0;
    };
    ok($ok, "print does not crash after mock destruction");
    ok(!$ret, "print returns false when mock is destroyed");
    is($errno, EBADF, "errno is EBADF after print on destroyed mock");

    close $fh;
};

subtest 'printf after mock destruction returns false' => sub {
    my $fh = _open_then_destroy_mock('/fake/printf', '', '>');

    my ($ret, $errno);
    my $ok = lives {
        $ret = printf {$fh} "%s", "hello";
        $errno = $! + 0;
    };
    ok($ok, "printf does not crash after mock destruction");
    ok(!$ret, "printf returns false when mock is destroyed");
    is($errno, EBADF, "errno is EBADF after printf on destroyed mock");

    close $fh;
};

subtest 'syswrite after mock destruction returns 0' => sub {
    my $fh = _open_then_destroy_mock('/fake/syswrite', '', '>');

    my ($ret, $errno);
    my $ok = lives {
        $ret = syswrite($fh, "hello", 5);
        $errno = $! + 0;
    };
    ok($ok, "syswrite does not crash after mock destruction");
    is($ret, 0, "syswrite returns 0 bytes");
    is($errno, EBADF, "errno is EBADF after syswrite on destroyed mock");

    close $fh;
};

subtest 'eof after mock destruction returns true' => sub {
    my $fh = _open_then_destroy_mock('/fake/eof', "content");

    my $ret;
    my $ok = lives { $ret = eof($fh) };
    ok($ok, "eof does not crash after mock destruction");
    ok($ret, "eof returns true (handle is dead)");

    close $fh;
};

subtest 'seek after mock destruction fails gracefully' => sub {
    my $fh = _open_then_destroy_mock('/fake/seek', "content");

    my ($ret, $errno);
    my $ok = lives {
        $ret = seek($fh, 0, 0);
        $errno = $! + 0;
    };
    ok($ok, "seek does not crash after mock destruction");
    is($ret, 0, "seek returns 0 (failure)");
    is($errno, EBADF, "errno is EBADF after seek on destroyed mock");

    close $fh;
};

subtest 'tell after mock destruction still works' => sub {
    my $fh = _open_then_destroy_mock('/fake/tell', "content");

    my $ret;
    my $ok = lives { $ret = tell($fh) };
    ok($ok, "tell does not crash after mock destruction");
    is($ret, 0, "tell returns the last known position");

    close $fh;
};

subtest 'readline list context after mock destruction returns empty' => sub {
    my $fh = _open_then_destroy_mock('/fake/readline_list', "a\nb\n");

    my @lines;
    my $ok = lives { @lines = <$fh> };
    ok($ok, "readline (list) does not crash after mock destruction");
    is(scalar @lines, 0, "readline (list) returns empty list");

    close $fh;
};

subtest 'close after mock destruction succeeds' => sub {
    my $fh = _open_then_destroy_mock('/fake/close', "content");

    my $ret;
    my $ok = lives { $ret = close($fh) };
    ok($ok, "close does not crash after mock destruction");
    ok($ret, "close returns true");
};

done_testing();
