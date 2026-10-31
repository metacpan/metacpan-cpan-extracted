#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#
# GH-301: load_factory_script reports YATT::Lite modules loaded from
# a library root other than the running YATT::Lite (ie. a copy bundled
# in the app's lib/), instead of failing with an obscure error.
#
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::More;
use File::Temp qw(tempdir);

use YATT::t::t_preload; # To make Devel::Cover happy.

use YATT::Lite::Util qw(untaint_any);
use YATT::Lite::Util::File qw(mkfile_may_wait);
use YATT::Lite::Factory;
sub Factory () {'YATT::Lite::Factory'}

my $TMP = tempdir(CLEANUP => $ENV{NO_CLEANUP} ? 0 : 1);
END {
  chdir('/');
}

# app.psgi which loads $use (if any) before creating the site.
sub app_psgi {
  my ($appNS, $use, $after) = @_;
  <<END;
# -*- perl -*-
use strict;
use warnings;
use FindBin;
use lib "\$FindBin::Bin/lib";
use YATT::Lite::WebMVC0::SiteApp -as_base;
@{[$use ? "use $use;" : ""]}
{
  my \$SITE = MY->load_factory_for_psgi
    (\$0
     , app_ns => '$appNS'
     , doc_root => "\$FindBin::Bin/public"
    );
  @{[$after // ""]}
  return \$SITE if \$SITE->want_object;
  \$SITE->to_app;
}
END
}

# A (fake) bundled copy of a module. The running YATT::Lite has it too,
# but it is not loaded yet.
sub probe_pm {
  my ($name) = @_;
  "package YATT::Lite::$name; use strict; 1;\n";
}
sub probe_fn {
  my ($name) = @_;
  join("/", split /::/, "YATT::Lite::$name") . ".pm";
}

{
  my $app = untaint_any("$TMP/plain");
  MY->mkfile_may_wait
    ("$app/app.psgi", app_psgi('TestMixedLib1')
     , "$app/public/index.yatt", "<h1>hi</h1>\n");

  my $site = eval {Factory->load_factory_script("$app/app.psgi")};
  is($@, '', "no error without bundled YATT::Lite");
  ok($site, "site is loaded");
}

{
  my $app = untaint_any("$TMP/mixed");
  MY->mkfile_may_wait
    ("$app/app.psgi", app_psgi('TestMixedLib2'
                               , 'YATT::Lite::WebMVC0::Partial::Session3 ()')
     , "$app/lib/".probe_fn('WebMVC0::Partial::Session3')
     , probe_pm('WebMVC0::Partial::Session3')
     , "$app/public/index.yatt", "<h1>hi</h1>\n");

  eval {Factory->load_factory_script("$app/app.psgi")};
  like($@, qr{^Mixed YATT::Lite library roots}, "mixed roots are reported");
  like($@, qr{YATT/Lite/WebMVC0/Partial/Session3\.pm from \S*/mixed/lib\n}
       , "the module and its root are shown");
  unlike($@, qr{Original error}, "no original error");
}

{
  my $app = untaint_any("$TMP/mixed_die");
  MY->mkfile_may_wait
    ("$app/app.psgi", app_psgi('TestMixedLib3'
                               , 'YATT::Lite::WebMVC0::Partial::LangSwitch ()'
                               , 'die "Boom in app.psgi\n";')
     , "$app/lib/".probe_fn('WebMVC0::Partial::LangSwitch')
     , probe_pm('WebMVC0::Partial::LangSwitch')
     , "$app/public/index.yatt", "<h1>hi</h1>\n");

  eval {Factory->load_factory_script("$app/app.psgi")};
  like($@, qr{^Mixed YATT::Lite library roots}
       , "mixed roots are reported even if loading dies");
  like($@, qr{YATT/Lite/WebMVC0/Partial/LangSwitch\.pm from }, "the module is shown");
  like($@, qr{Original error: Boom in app\.psgi}, "the original error is kept");
}

{
  # App's own module under YATT::Lite namespace is not a mixing.
  my $app = untaint_any("$TMP/own_module");
  MY->mkfile_may_wait
    ("$app/app.psgi", app_psgi('TestMixedLib5', 'YATT::Lite::MixedLibAppOnly')
     , "$app/lib/".probe_fn('MixedLibAppOnly'), probe_pm('MixedLibAppOnly')
     , "$app/public/index.yatt", "<h1>hi</h1>\n");

  my $site = eval {Factory->load_factory_script("$app/app.psgi")};
  is($@, '', "app's own YATT::Lite::* module is not reported");
  ok($site, "site is loaded");
}

{
  # Modules mixed by an earlier load are not reported again.
  my $app = untaint_any("$TMP/plain2");
  MY->mkfile_may_wait
    ("$app/app.psgi", app_psgi('TestMixedLib4')
     , "$app/public/index.yatt", "<h1>hi</h1>\n");

  my $site = eval {Factory->load_factory_script("$app/app.psgi")};
  is($@, '', "a later load is not affected by earlier mixing");
  ok($site, "site is loaded");
}

done_testing();
