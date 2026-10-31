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

use_ok('YATT::Lite::CLI');
use_ok('YATT::Lite::CLI::Render');

my $TMP = tempdir(CLEANUP => $ENV{NO_CLEANUP} ? 0 : 1);
END {
  chdir('/');
}

#========================================
# Fixture
#========================================
my $dir = untaint_any("$TMP/docs");
{
  MY->mkfile_may_wait
    ("$dir/hello.yatt", <<'END'
<!yatt:args name>
<h2>Hello &yatt:name;!</h2>
END

     , "$dir/bye.yatt", <<'END'
<!yatt:args name>
<h2>Bye &yatt:name;!</h2>
END

     , "$dir/die.yatt", <<'END'
<!yatt:args>
<?perl die "boom!\n"?>
END

     , "$dir/notfound.yatt", <<'END'
<!yatt:args>
<?perl $CON->raise_response([404, [], ["gone"]])?>
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
# Single file with params
#========================================
{
  my $exit;
  my $out = capture {
    $exit = YATT::Lite::CLI::Render->run(["$dir/hello.yatt", "name=world"]);
  };
  is $exit, 0, "exit code 0 on success";
  like $out, qr{<h2>Hello world!</h2>}, "renders file with param";
}

#========================================
# Common params + per-file params
#========================================
{
  my $out = capture {
    YATT::Lite::CLI::Render->run
      (["name=common", "$dir/hello.yatt", "$dir/bye.yatt", "name=special"]);
  };
  like $out, qr{Hello common!}, "common param applies to first file";
  like $out, qr{Bye special!}, "per-file param overrides common";
}

#========================================
# Error policy: raw die passes through (perl -d friendly)
#========================================
{
  my $err = catch {
    capture { YATT::Lite::CLI::Render->run(["$dir/die.yatt"]) };
  };
  like $err, qr/boom!/, "raw die from template propagates to caller";
  ok((not defined $SIG{__DIE__} and not defined $SIG{__WARN__})
     , "CLI layer never leaves SIG handlers installed");
}

#========================================
# Non-success response => exit 1 + stderr line
#========================================
{
  my ($exit, $errout);
  my $out = capture {
    $errout = capture_err {
      $exit = YATT::Lite::CLI::Render->run(["$dir/notfound.yatt"]);
    };
  };
  is $exit, 1, "exit code 1 on non-success response";
  like $errout, qr/404/, "status line goes to stderr";
  unlike $out, qr/gone/, "body of failed response is not printed to stdout";
}

#========================================
# Script smoke test (same behavior via scripts/yatt.render)
#========================================
{
  my $script = untaint_any("$FindBin::Bin/../scripts/yatt.render");
  ok -x $script || -r $script, "scripts/yatt.render exists";
  my $out = qx{$^X $script "$dir/hello.yatt" name=cmdline 2>/dev/null};
  is $? >> 8, 0, "script exits 0";
  like $out, qr{<h2>Hello cmdline!</h2>}, "script renders like the module";
}

done_testing();
