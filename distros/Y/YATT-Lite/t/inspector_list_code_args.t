#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#
# GH-300: Inspector list_code_args lists code-type argument declarations
# in yatt declarations (<!yatt:args>, <!yatt:widget>, ...).
#
#  - body (implicit or explicit) is excluded by default
#  - with_body includes body
#  - type selects another type (ie. expr)
#
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::More;
use File::Temp qw(tempdir);
use File::Basename qw(dirname);

use YATT::t::t_preload; # To make Devel::Cover happy.

use YATT::Lite::Util qw(untaint_any);
use YATT::Lite::Util::File qw(mkfile_may_wait);

BEGIN {
  foreach my $req (qw(Plack Plack::Response Hash::MultiValue
                      File::AddInc MOP4Import::Base::CLI_JSON Text::Glob
                      Test::Command)) {
    unless (eval qq{require $req}) {
      plan skip_all => "$req is not installed."; exit;
    }
  }
}

use YATT::Lite::Inspector;

my $distDir = dirname($FindBin::Bin);

my $TMP = tempdir(CLEANUP => $ENV{NO_CLEANUP} ? 0 : 1);
END {
  chdir('/');
}

#========================================
# Fixture
#========================================
my $app = untaint_any("$TMP/app");

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
     , app_ns => 'TestInspCodeArgs1'
     , doc_root => "$FindBin::Bin/public"
     , app_base => '@ytmpl'
    );
  if ($SITE->want_object) {
    return $SITE;
  } else {
    return $SITE->to_app;
  }
}
END
   , "$app/public/index.yatt", <<'END'
<!yatt:args
  title
  f=[code x y]
  footer=code
  calc=[expr n]
>
<h1>&yatt:title;</h1>
<!yatt:widget w g=[code] body=[code z]>
<yatt:body z=1/>
END
   , "$app/public/plain.yatt", <<'END'
<p>No args</p>
END
   , "$app/ytmpl/layout.ytmpl", <<'END'
<!yatt:args header=code>
<div><yatt:header/><yatt:body/></div>
END
  );

my $ins = YATT::Lite::Inspector->new(dir => $app);

sub list_of {
  my @list = sort {
    $a->{path} cmp $b->{path} or $a->{line} <=> $b->{line}
  } $ins->list_code_args(@_);
  [map {
    join " ", $_->{path}, $_->{line}, $_->{kind}, $_->{name}
      , "$_->{arg}=$_->{spec}"
  } @list];
}

is_deeply list_of(), [
  "public/index.yatt 3 page index f=[code x y]",
  "public/index.yatt 4 page index footer=code",
  "public/index.yatt 8 widget index:w g=code",
  "ytmpl/layout.ytmpl 1 widget layout header=code",
], "code args, without body";

{
  my @with_body = @{list_of(with_body => 1)};
  my @body = grep {/ body=/} @with_body;
  ok(scalar(grep {$_ eq "public/index.yatt 8 widget index:w body=[code z]"}
            @body), "explicit body is listed with with_body");
  ok(scalar(grep {m{^public/plain\.yatt .* body=code$}} @body)
     , "implicit body is listed with with_body");
  is(@with_body - @body, 4, "with_body does not change non-body results");
}

is_deeply list_of(type => 'expr'), [
  "public/index.yatt 5 page index calc=[expr n]",
], "type => expr";

SKIP: {
  # Running Lite/Inspector.pm as a modulino needs File::AddInc to map its
  # path to YATT/Lite/Inspector.pm, which only works when the checkout
  # is named YATT (not in a dist dir like YATT-Lite-X.Y, see inspector.t).
  skip "CLI tests only work when \$distDir ends with 'YATT'", 6
    unless [File::Spec->splitdir($distDir)]->[-1] eq "YATT";

  my $cmd = Test::Command->new(cmd => [
    "$distDir/Lite/Inspector.pm",
    "--dir=$app",
    "--output=tsv",
    "list_code_args",
  ]);

  $cmd->exit_is_num(0);
  is $cmd->stderr_value, '', "list_code_args runs without error";
  my @lines = sort split /\n/, $cmd->stdout_value;
  is scalar(@lines), 4, "CLI emits one line per code arg";
  like $lines[0], qr{^public/index\.yatt\t3\tpage\tindex\tf\t\[code x y\]$}
    , "CLI tsv line";

  # command specific options and global options after the command name
  $cmd = Test::Command->new(cmd => [
    "$distDir/Lite/Inspector.pm",
    "--dir=$app",
    "list_code_args",
    "--type=expr",
    "--output=tsv",
  ]);

  $cmd->exit_is_num(0);
  is $cmd->stdout_value, "public/index.yatt\t5\tpage\tindex\tcalc\t[expr n]\n"
    , "CLI options after the command";
}

done_testing();
