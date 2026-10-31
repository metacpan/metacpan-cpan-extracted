#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#
# YATT::Lite::Util::File->mkfile_may_wait の契約:
#
#  - 書き換え時に mtime の厳密な前進を保証する。そのために
#    旧 mtime + 1.05 秒まで実時間で眠ることがある(通常は最大 ~1 秒)。
#  - 新規作成では眠らない。
#  - mtime が大きく未来のファイル(テスト側が utime で進めたもの)には
#    黙って長時間眠らず croak する。mtime 前進は may_wait 自身が保証するので、
#    utime で mtime を進める運用と併用してはならない。
#  - 旧名 mkfile は互換のための alias。
#
# 背景: t/lite_import.t の旧 $rewrite が utime(time+100) で mtime を進めた
# ファイルに旧 mkfile を再度呼び、内蔵の「旧 mtime + 1.05 秒まで待つ」機能が
# 約 100 秒の silent stall を起こしていた。
#
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::Kantan;
use File::Temp qw/tempdir/;
use File::stat;
use Time::HiRes ();

use YATT::Lite::Util::File ();

my $tempdir = tempdir(CLEANUP => 1);
END {chdir "/"}

my $read_file = sub {
  my ($fn) = @_;
  open my $fh, '<', $fn or die "$fn: $!";
  local $/; scalar <$fh>;
};

describe "mkfile_may_wait", sub {

  it "should create a fresh file (with parent dirs) without sleeping", sub {
    my $fn = "$tempdir/sub/dir/fresh.txt";
    my $start = Time::HiRes::time;
    YATT::Lite::Util::File->mkfile_may_wait($fn => "hello");
    my $elapsed = Time::HiRes::time - $start;
    expect($read_file->($fn))->to_be("hello");
    expect($elapsed < 3)->to_be_truthy;
  };

  it "should advance mtime strictly on immediate rewrite (may sleep ~1 sec)", sub {
    my $fn = "$tempdir/rewrite.txt";
    YATT::Lite::Util::File->mkfile_may_wait($fn => "v1");
    my $old_mtime = stat($fn)->mtime;
    YATT::Lite::Util::File->mkfile_may_wait($fn => "v2");
    expect($read_file->($fn))->to_be("v2");
    expect(stat($fn)->mtime > $old_mtime)->to_be_truthy;
  };

  it "should croak instead of sleeping when mtime is far in the future", sub {
    my $fn = "$tempdir/future.txt";
    YATT::Lite::Util::File->mkfile_may_wait($fn => "v1");
    # 誤用のシミュレート: テスト側が utime で mtime を未来へ飛ばした状態
    utime(time + 8, time + 8, $fn);
    my $start = Time::HiRes::time;
    my $err = do {
      local $@ = '';
      eval { YATT::Lite::Util::File->mkfile_may_wait($fn => "v2") };
      '' . $@;
    };
    my $elapsed = Time::HiRes::time - $start;
    expect($err)->to_match(qr/in the future/);
    expect($elapsed < 5)->to_be_truthy;
  };

  it "should keep mkfile as an alias of mkfile_may_wait", sub {
    expect(\&YATT::Lite::Util::File::mkfile
           == \&YATT::Lite::Util::File::mkfile_may_wait)->to_be_truthy;
  };
};

done_testing();
