#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::More;

{
  BEGIN {
    use_ok('YATT::Lite::Util', qw/incr_opt unique/);
  }

  my $list = [qw/foo bar/];
  is_deeply [incr_opt(depth => $list), $list]
    , [{depth => 1}, $list], "no hash";

  $list = [{}, qw/foo bar/];
  is_deeply [incr_opt(depth => $list), $list]
    , [{depth => 1}, $list], "has hash but no depth";

  $list = [{depth => 1}, qw/foo bar/];
  is_deeply [incr_opt(depth => $list), $list]
    , [{depth => 2}, $list], "depth is incremented";

  is_deeply [unique qw/foo bar foo/], [qw/foo bar/]
    , "(order preserving) unique";
}

{
  package
    t_test1;
  sub render_q1 {
    my ($this, $con, $arg) = @_;
    print $con "[[$arg]]";
  }
  sub render_q_bar {
    my ($this, $con, $arg) = @_;
    print $con "(($arg))";
  }
  Test::More::is YATT::Lite::Util::captured {
    my ($fh) = @_;
    YATT::Lite::Util::safe_render(__PACKAGE__, $fh, q1 => "foo");
  }, "[[foo]]", "safe_render str";

  Test::More::is YATT::Lite::Util::captured {
    my ($fh) = @_;
    YATT::Lite::Util::safe_render(__PACKAGE__, $fh, [q => "bar"] => "barr");
  }, "((barr))", "safe_render list";

  Test::More::like do {eval {YATT::Lite::Util::captured {
    my ($fh) = @_;
    YATT::Lite::Util::safe_render(__PACKAGE__, $fh, unknown => "unk");
  }}; $@}, qr/^Can't find widget 'unknown'/, "safe_render unknown";

  package
    t_dummy_con;
  sub raise {}
  sub error {
    my ($this, $errfmt, @args) = @_;
    die "DUMMY[".sprintf($errfmt, @args)."]\n";
  }

  Test::More::like do {eval {
    YATT::Lite::Util::safe_render(__PACKAGE__, __PACKAGE__, unknown => "unk2");
  }; $@}, qr/^DUMMY\[Can't find widget 'unknown'\]/
    , "safe_render with raise-able connection";
}

done_testing();
