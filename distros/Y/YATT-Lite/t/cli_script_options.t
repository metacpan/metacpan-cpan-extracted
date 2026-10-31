#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#
# GH-233: scripts/yatt* must accept their options (fields without cf_ prefix).
#
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::More;
use IPC::Open3;
use Symbol qw(gensym);
use Cwd qw(getcwd);

use File::Temp qw(tempdir);

use YATT::Lite::Util qw(untaint_any);
use YATT::Lite::Util::File qw(mkfile_may_wait);

if ($^O =~ /^MSWin/) {
  plan skip_all => "pipe open is not supported on windows";
}

$ENV{LANG} = "C"; # To avoid Wide char in $!

my $dist = untaint_any(Cwd::realpath("$FindBin::Bin/.."));
my $app = untaint_any("$dist/samples/basic/1");

# Returns (exit status, stdout, stderr)
sub run_script {
  my ($dir, $script, @args) = @_;
  my $cwd = getcwd;
  chdir($dir) or die "Can't chdir to $dir: $!";
  my @opts = split " ", $ENV{HARNESS_PERL_SWITCHES} // '';
  my $pid = open3(my $in, my $out, my $err = gensym
                  , $^X, @opts, "$dist/scripts/$script", @args);
  close $in;
  my ($stdout, $stderr) = do {local $/; (scalar(<$out>) // '', scalar(<$err>) // '')};
  waitpid($pid, 0);
  chdir($cwd) or die "Can't chdir back to $cwd: $!";
  ($? >> 8, $stdout, $stderr);
}

{
  my ($rc, $out, $err) = run_script($app, 'yatt', '--help');
  unlike $err, qr/No such config item/, "yatt --help: option is accepted";
  like $err, qr/^Usage: /, "yatt --help: shows usage";
}

{
  my ($rc, $out, $err) = run_script($app, 'yatt.info', '--linear', 'isa');
  is $err, '', "yatt.info --linear isa: no error";
  like $out, qr/^dispatcher=\S+\n(?:  \S+\t.*\n)*  YATT::Lite::WebMVC0::SiteApp\t/
    , "yatt.info --linear isa: linear isa is shown";
}

SKIP: {
  skip "Locale::PO is not installed", 4
    unless eval {require Locale::PO};
  my $tmp = untaint_any(tempdir(CLEANUP => $ENV{NO_CLEANUP} ? 0 : 1));
  MY->mkfile_may_wait
    ("$tmp/app.psgi", <<'END'
use strict;
use FindBin;
use YATT::Lite::WebMVC0::SiteApp -as_base;
{
  my $SITE = MY->load_factory_for_psgi
    ($0, app_ns => 'TestCLIXgettext', doc_root => "$FindBin::Bin/public");
  return $SITE if $SITE->want_object;
  $SITE->to_app;
}
END
     , "$tmp/public/index.yatt", <<'END');
<!yatt:args user>
<h2>&yatt[[;Hello &yatt:user;!&yatt]];</h2>
END
  my ($rc, $out, $err) = run_script($dist, 'yatt.xgettext'
                                    , '--quiet', "--dir=$tmp");
  is $err, '', "yatt.xgettext --quiet --dir: no error";
  is $rc, 0, "yatt.xgettext --quiet --dir: exit 0";
  like $out, qr/^msgid ""/m, "yatt.xgettext --quiet --dir: po header";
  like $out, qr/^msgid "Hello %s!"/m, "yatt.xgettext --quiet --dir: message is extracted";
}

done_testing();
