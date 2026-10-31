#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------
#
# Factory->find_factory_script($dir, stop_at => $boundary) and the
# Site->load / load_or_default options built on it: the upward search
# for app.psgi must never leave $boundary, so a script planted above a
# workspace is not found (and therefore never executed).
#

use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);

use YATT::t::t_preload; # To make Devel::Cover happy.
use YATT::Lite::Util qw(untaint_any catch);
use YATT::Lite::Util::File qw(mkfile_may_wait);
use YATT::Lite::Factory;
use YATT::Lite::Site;

my $TMP = untaint_any(tempdir(CLEANUP => $ENV{NO_CLEANUP} ? 0 : 1));
END { chdir('/') }

#
# $TMP/parent/app.psgi      <- must NOT run when the workspace is $TMP/parent/ws
# $TMP/parent/ws/index.yatt <- the workspace (no app.psgi of its own)
# $TMP/parent/ws/deep/
# $TMP/link -> $TMP/parent/ws
#
my $parent = "$TMP/parent";
my $ws = "$parent/ws";
my $deep = "$ws/deep";
my $marker = "$TMP/parent-app-executed";
make_path($deep);
symlink $ws, "$TMP/link" or die "symlink: $!";

MY->mkfile_may_wait("$ws/index.yatt", "hello\n");
MY->mkfile_may_wait("$parent/app.psgi", <<"END");
# -*- perl -*-
use strict;
use warnings;
use FindBin;
# Leave a trace when this script is executed.
open my \$fh, '>>', q{$marker} or die \$!; print \$fh "executed\\n"; close \$fh;
use YATT::Lite::WebMVC0::SiteApp -as_base;
{
  my \$SITE = MY->load_factory_for_psgi
    (\$0, app_ns => 'TestStopAtParentApp', doc_root => "\$FindBin::Bin/ws");
  if (\$SITE->want_object) { return \$SITE } else { return \$SITE->to_app }
}
END

my $F = 'YATT::Lite::Factory';

#========================================
subtest "find_factory_script without stop_at (unchanged)", sub {
  is $F->find_factory_script($deep), "$parent/app.psgi", "found from deep";
  is $F->find_factory_script($ws), "$parent/app.psgi", "found from ws";
  # The walk is lexical (no realpath on the start), as before: climbing
  # from $TMP/link/deep passes $TMP/link and $TMP, never $TMP/parent.
  ok !defined $F->find_factory_script("$TMP/link/deep")
    , "symlinked start: the lexical walk does not pass through parent/";
  ok !-e $marker, "search alone never executes the script";
};

#========================================
subtest "find_factory_script with stop_at", sub {
  ok !defined $F->find_factory_script($deep, stop_at => $ws)
    , "stop_at => ws: parent/app.psgi is out of bounds";
  ok !defined $F->find_factory_script($ws, stop_at => $ws)
    , "start == boundary, no script there: nothing";
  ok !defined $F->find_factory_script($deep, stop_at => $deep)
    , "stop_at => deep: not even ws is looked at";
  is $F->find_factory_script($deep, stop_at => $parent), "$parent/app.psgi"
    , "stop_at => parent: the script in parent itself is found";
  is $F->find_factory_script($deep, stop_at => $TMP), "$parent/app.psgi"
    , "stop_at above the script: found";

  # symlinks: boundary and start are compared by realpath.
  ok !defined $F->find_factory_script("$TMP/link/deep", stop_at => "$TMP/link")
    , "symlinked boundary: out of bounds";
  ok !defined $F->find_factory_script("$TMP/link/deep", stop_at => $ws)
    , "symlinked start, real boundary: out of bounds";
  ok !defined $F->find_factory_script("$TMP/link/deep", stop_at => $TMP)
    , "symlinked start, wide boundary: still nothing (lexical walk, see above)";
  MY->mkfile_may_wait("$TMP/link/runyatt.psgi", "1;\n"); # == $ws/runyatt.psgi
  is $F->find_factory_script("$TMP/link/deep", stop_at => "$TMP/link")
    , "$TMP/link/runyatt.psgi", "symlinked start and boundary: found inside";
  is $F->find_factory_script("$TMP/link/deep", stop_at => $ws)
    , "$TMP/link/runyatt.psgi", "symlinked start, real boundary: found inside";
  unlink "$ws/runyatt.psgi";

  # A script inside the boundary is found.
  MY->mkfile_may_wait("$deep/runyatt.psgi", "1;\n");
  is $F->find_factory_script($deep, stop_at => $deep), "$deep/runyatt.psgi"
    , "script in the boundary dir itself is found";
  is $F->find_factory_script("$deep/x/y", stop_at => $deep), "$deep/runyatt.psgi"
    , "from a (non-existent) subdir of the boundary: found";
  unlink "$deep/runyatt.psgi";

  ok !-e $marker, "search alone never executes the script";
};

#========================================
subtest "Site->load_or_default with stop_at falls back to a default site", sub {
  my $site = YATT::Lite::Site->load_or_default(dir => $ws, stop_at => $ws);
  isa_ok $site, 'YATT::Lite::WebMVC0::SiteApp';
  is $site->cget('app_root'), $ws, "default site rooted at the workspace";
  isnt $site->cget('app_ns'), 'TestStopAtParentApp', "not the parent's site";
  ok !-e $marker, "parent/app.psgi was NOT executed";
};

#========================================
subtest "Site->load with stop_at dies instead of climbing", sub {
  my $err = catch { YATT::Lite::Site->load(dir => $ws, stop_at => $ws) };
  like $err, qr/Can't find factory script .*\(search stopped at: \Q$ws\E\)/
    , "dies and names the boundary";
  ok !-e $marker, "parent/app.psgi was NOT executed";
};

#========================================
subtest "Inspector with search_boundary", sub {
  foreach my $req (qw(File::AddInc MOP4Import::Base::CLI_JSON Text::Glob File::Slurp Try::Tiny)) {
    unless (eval qq{require $req; 1}) {
      plan skip_all => "$req is not installed.";
    }
  }
  require YATT::Lite::Inspector;
  my $insp = YATT::Lite::Inspector->new(dir => $ws, search_boundary => $ws);
  is $insp->{_app_root}, $ws, "Inspector's app_root is the workspace";
  ok !-e $marker, "parent/app.psgi was NOT executed";
};

#========================================
subtest "without stop_at the parent's script is loaded (sanity)", sub {
  my $site = YATT::Lite::Site->load_or_default(dir => $ws);
  is $site->cget('app_ns'), 'TestStopAtParentApp', "parent's site";
  ok -e $marker, "parent/app.psgi was executed";
};

done_testing();
