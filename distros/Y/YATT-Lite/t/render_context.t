#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::More;
use File::Temp qw(tempdir);
use Cwd ();

use YATT::t::t_preload; # To make Devel::Cover happy.

use YATT::Lite::Util qw(catch untaint_any);
use YATT::Lite::Util::File qw(mkfile_may_wait);

BEGIN {
  foreach my $req (qw(Plack Plack::Test Plack::Response Hash::MultiValue)) {
    unless (eval qq{require $req;}) {
      plan skip_all => "$req is not installed."; exit;
    }
  }
}

use YATT::Lite::Site;
require YATT::Lite::WebMVC0::SiteApp;

my $TMP = tempdir(CLEANUP => $ENV{NO_CLEANUP} ? 0 : 1);
END {
  chdir('/');
}

#========================================
# Fixture: a template which reads a sibling file with a RELATIVE path.
# "The cwd of a template is its directory" is the official semantics
# under test here.
#========================================
my $dir = untaint_any("$TMP/docs");
{
  MY->mkfile_may_wait
    ("$dir/rel.yatt", <<'END'
<!yatt:args>
<?perl= do {open my $fh, '<', "data.txt" or die "CANT_OPEN data.txt: $!"; local $/; my $body = <$fh>; close $fh; $body}?>
END

     , "$dir/data.txt", "RELDATA\n");
}

my $CWD0 = Cwd::getcwd();

my $site = YATT::Lite::Site->load_or_default(dir => $dir);

#========================================
# chdir_guard: scoped chdir with restore (even via die)
#========================================
{
  my ($dh) = $site->resolve_file("$dir/rel.yatt");
  ok $dh->can('chdir_guard'), "dirhandler has chdir_guard";
  {
    my $guard = $dh->chdir_guard;
    is Cwd::realpath(Cwd::getcwd()), Cwd::realpath($dh->cget('dir'))
      , "guard chdirs into the dirhandler dir";
  }
  is Cwd::getcwd(), $CWD0, "guard restores cwd on scope exit";

  my $err = catch {
    my $guard = $dh->chdir_guard;
    die "inner\n";
  };
  is $err, "inner\n", "die propagates through the guard scope";
  is Cwd::getcwd(), $CWD0, "cwd is restored even when the scope dies";
}

#========================================
# render_file (handle path): relative read works AND cwd is restored
#========================================
{
  my $res = $site->render_file("$dir/rel.yatt", {});
  like $res->content, qr/RELDATA/
    , "render_file: template can read sibling file relatively";
  is Cwd::getcwd(), $CWD0, "render_file: cwd is restored afterwards";
}

#========================================
# request (web path): same, and cwd is restored after the request
#========================================
{
  my $res = $site->request(GET => '/rel');
  like $res->content, qr/RELDATA/
    , "request: template can read sibling file relatively";
  is Cwd::getcwd(), $CWD0, "request: cwd is restored afterwards";
}

#========================================
# Factory::render (render path): chdir now applies here too (GH-267)
#========================================
{
  my $out = $site->render('/rel', {});
  like $out, qr/RELDATA/
    , "render: template can read sibling file relatively";
  is Cwd::getcwd(), $CWD0, "render: cwd is restored afterwards";
}

#========================================
# render path now runs before/after_dirhandler (site_config hooks)
#========================================
{
  my $called = 0;
  my $orig = YATT::Lite::WebMVC0::SiteApp->can('before_dirhandler');
  no warnings qw(redefine once);
  local *YATT::Lite::WebMVC0::SiteApp::before_dirhandler = sub {
    $called++; goto &$orig;
  };
  $site->render('/rel', {});
  cmp_ok $called, '>=', 1, "before_dirhandler runs in the render path";
}

#========================================
# no_chdir (Compatibility option): opt-out for embedded/threaded hosts
#========================================
{
  my $nosite = YATT::Lite::Site->load_or_default(dir => $dir, no_chdir => 1);
  my $err = catch { $nosite->render_file("$dir/rel.yatt", {}) };
  like $err, qr/CANT_OPEN data\.txt/
    , "no_chdir: relative read fails (cwd is left alone)";
  is Cwd::getcwd(), $CWD0, "no_chdir: cwd is untouched";
}

#========================================
# $CON->system: official accessor for the $SYS derivation
#========================================
{
  my $con = $site->make_connection(undef, noheader => 1);
  ok $con->can('system'), '$CON can system';
  is $con->system, $site, '$CON->system returns the site ($SYS)';
  is $con->cget('system'), $site, "cget('system') agrees";
}

done_testing();
