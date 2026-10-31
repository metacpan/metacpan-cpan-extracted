#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::More;
use File::Temp qw(tempdir);

use YATT::t::t_preload; # To make Devel::Cover happy.

use YATT::Lite::Util qw(catch untaint_any);
use YATT::Lite::Util::File qw(mkfile_may_wait);

BEGIN {
  foreach my $req (qw(Plack Plack::Response Hash::MultiValue)) {
    unless (eval qq{require $req;}) {
      plan skip_all => "$req is not installed."; exit;
    }
  }
}

use_ok('YATT::Lite::CLI::GenPerl');

my $TMP = tempdir(CLEANUP => $ENV{NO_CLEANUP} ? 0 : 1);
END {
  chdir('/');
}

#========================================
# Fixture: uses.yatt depends on a widget in parts.ytmpl
#========================================
my $dir = untaint_any("$TMP/docs");
{
  MY->mkfile_may_wait
    ("$dir/uses.yatt", <<'END'
<!yatt:args>
<yatt:parts:navi/>
END

     , "$dir/parts.ytmpl", <<'END'
<!yatt:widget navi>
<ul><li>navi</li></ul>
END
    );
}

sub capture (&) {
  my ($code) = @_;
  local *STDOUT;
  open STDOUT, '>', \ (my $out = '') or die "Can't redirect STDOUT: $!";
  $code->();
  close STDOUT;
  $out;
}

sub capture_err (&) {
  my ($code) = @_;
  local *STDERR;
  open STDERR, '>', \ (my $err = '') or die "Can't redirect STDERR: $!";
  $code->();
  close STDERR;
  $err;
}

#========================================
# Default: emits the target's generated perl only (depth == 1)
#========================================
{
  my $exit;
  my $out = capture {
    $exit = YATT::Lite::CLI::GenPerl->run(["$dir/uses.yatt"]);
  };
  is $exit, 0, "exit 0";
  like $out, qr/package .*::uses;/, "emits generated package for the target";
  like $out, qr/sub render_/, "emits render sub";
  unlike $out, qr/sub render_navi\b/, "dependency script is not emitted by default";
}

#========================================
# --all: dependencies' generated perl is emitted too
#========================================
{
  my $out = capture {
    YATT::Lite::CLI::GenPerl->run(["--all", "$dir/uses.yatt"]);
  };
  like $out, qr/sub render_navi\b/, "--all emits dependency script too";
}

#========================================
# Missing file => warning + exit 1
#========================================
{
  my ($exit, $errout);
  capture {
    $errout = capture_err {
      $exit = YATT::Lite::CLI::GenPerl->run(["$dir/no_such.yatt"]);
    };
  };
  is $exit, 1, "missing file => exit 1";
  like $errout, qr/No such file/, "missing file => warning";
}

#========================================
# Script smoke test
#========================================
{
  my $script = untaint_any("$FindBin::Bin/../scripts/yatt.genperl");
  my $out = qx{$^X $script "$dir/uses.yatt" 2>/dev/null};
  is $? >> 8, 0, "script exits 0";
  like $out, qr/sub render_/, "script emits generated perl";
}

done_testing();
