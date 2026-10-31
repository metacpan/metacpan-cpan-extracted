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
  unless (eval {require YATT::Lite::Inspector}) {
    plan skip_all => "YATT::Lite::Inspector is not loadable: $@"; exit;
  }
}

use_ok('YATT::Lite::CLI::Lint');

my $TMP = tempdir(CLEANUP => $ENV{NO_CLEANUP} ? 0 : 1);
END {
  chdir('/');
}

#========================================
# Fixture: an app (with app.psgi) and a bare template dir (without)
#========================================
my $app = untaint_any("$TMP/app");
{
  MY->mkfile_may_wait
    ("$app/app.psgi", <<'END'
# -*- perl -*-
use strict;
use warnings;
use FindBin;
use YATT::Lite::WebMVC0::SiteApp -as_base;
{
  my $SITE = MY->load_factory_for_psgi
    ($0
     , app_ns => 'TestCliLintApp1'
     , doc_root => "$FindBin::Bin/public"
    );
  if ($SITE->want_object) {
    return $SITE;
  } else {
    return $SITE->to_app;
  }
}
END

     , "$app/public/good.yatt", <<'END'
<!yatt:args>
fine
END

     # Note: each block below lints a FRESH bad file. Re-linting the
     # same unchanged-but-broken template within one process returns a
     # false success (stale product left by the failed compile - the
     # GH-263 "failed load leftovers" problem), so we avoid depending
     # on it here.
     , (map {
       ("$app/public/bad$_.yatt", <<'END')
<!yatt:args>
<yatt:no_such_widget/>
END
     } (1..3, '_tap', '_script', '_old')),
    );
}

my $bare = untaint_any("$TMP/bare");
{
  MY->mkfile_may_wait
    ("$bare/good.yatt", <<'END'
<!yatt:args>
bare fine
END

     , "$bare/bad.yatt", <<'END'
<!yatt:args>
<yatt:no_such_widget/>
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
# Success => exit 0, silent
#========================================
{
  my ($exit, $errout);
  my $out = capture {
    $errout = capture_err {
      $exit = YATT::Lite::CLI::Lint->run(["$app/public/good.yatt"]);
    };
  };
  is $exit, 0, "good file => exit 0";
  is $out, '', "good file => stdout silent";
  is $errout, '', "good file => stderr silent";
}

#========================================
# Failure => exit 1, file:line: message on stderr
#========================================
{
  my ($exit, $errout);
  capture {
    $errout = capture_err {
      $exit = YATT::Lite::CLI::Lint->run(["$app/public/bad1.yatt"]);
    };
  };
  is $exit, 1, "bad file => exit 1";
  like $errout, qr/No such widget/, "error message on stderr";
  like $errout, qr/bad1\.yatt:2:/, "file:line: prefix points at the error line";
}

#========================================
# Without --all: stop at first failure. With --all: check everything.
#========================================
{
  my ($exit, $errout);
  capture {
    $errout = capture_err {
      $exit = YATT::Lite::CLI::Lint->run
	(["$app/public/bad2.yatt", "$app/public/good.yatt"]);
    };
  };
  is $exit, 1, "stops at first failure without --all";

  my $count;
  capture {
    $errout = capture_err {
      $exit = YATT::Lite::CLI::Lint->run
	(["--all", "$app/public/bad3.yatt", "$bare/bad.yatt"]);
    };
  };
  is $exit, 1, "--all still exits 1";
  $count = () = $errout =~ /No such widget/g;
  is $count, 2, "--all reports every failure";
}

#========================================
# --tap mode
#========================================
{
  my $exit;
  my $out = capture {
    capture_err {
      $exit = YATT::Lite::CLI::Lint->run
	(["--tap", "$app/public/good.yatt", "$app/public/bad_tap.yatt"]);
    };
  };
  like $out, qr/^1\.\.2\n/, "tap plan";
  like $out, qr/^ok 1 - /m, "tap ok line";
  like $out, qr/^not ok 2 - /m, "tap not ok line";
  like $out, qr/^# .*No such widget/m, "tap diagnostics as comments";
  is $exit, 1, "tap mode exit 1 on failure";
}

#========================================
# --format=old : the historical shape yatt-lint-any-mode.el parses
#========================================
{
  my ($exit, $errout);
  capture {
    $errout = capture_err {
      $exit = YATT::Lite::CLI::Lint->run
	(["--format=old", "$app/public/bad_old.yatt"]);
    };
  };
  is $exit, 1, "--format=old: exit 1";
  like $errout
    , qr/^error \[\[file\] [^\]]*bad_old\.yatt \[line\] 2\]\n No such widget/
    , "--format=old: 'TYPE [[file] F [line] L]' header + indented message";
}

#========================================
# Bare dir (no app.psgi): Inspector falls back to a default site
#========================================
{
  my ($exit, $errout);
  capture {
    $errout = capture_err {
      $exit = YATT::Lite::CLI::Lint->run(["$bare/good.yatt"]);
    };
  };
  is $exit, 0, "bare dir: good file lints fine";

  capture {
    $errout = capture_err {
      $exit = YATT::Lite::CLI::Lint->run(["$bare/bad.yatt"]);
    };
  };
  is $exit, 1, "bare dir: bad file => exit 1";
  like $errout, qr/No such widget/, "bare dir: real lint error (not 'Can't find app script')";
}

#========================================
# Script smoke test
#========================================
{
  my $script = untaint_any("$FindBin::Bin/../scripts/yatt.lint");
  my $out = qx{$^X $script "$app/public/good.yatt" 2>/dev/null};
  is $? >> 8, 0, "script exits 0 for good file";

  $out = qx{$^X $script "$app/public/bad_script.yatt" 2>&1};
  isnt $? >> 8, 0, "script exits non-zero for bad file";
  like $out, qr/No such widget/, "script reports the error";
}

done_testing();
