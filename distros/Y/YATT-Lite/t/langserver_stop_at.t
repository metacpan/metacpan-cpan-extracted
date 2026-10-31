#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#
# The language server must only execute an app.psgi that lives in the
# workspace root the client named (rootUri). A script in a parent
# directory (e.g. /tmp/app.psgi for a workspace under /tmp, or the
# app.psgi of a repository whose sub-directory was opened) is not run.
#
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);

use YATT::t::t_preload; # To make Devel::Cover happy.

use YATT::Lite::Util qw(untaint_any);
use YATT::Lite::Util::File qw(mkfile_may_wait);

BEGIN {
  foreach my $req (qw(Coro Coro::AIO AnyEvent
                      File::AddInc MOP4Import::Base::CLI_JSON
                      Plack Plack::Response Hash::MultiValue Text::Glob)) {
    unless (eval qq{require $req;}) {
      plan skip_all => "$req is not installed."; exit;
    }
  }
  unless (eval {require YATT::Lite::LanguageServer}) {
    plan skip_all => "YATT::Lite::LanguageServer is not loadable: $@"; exit;
  }
}

my $TIMEOUT = $ENV{YATT_LANGSERVER_TEST_TIMEOUT} // 20;

use File::Basename qw(dirname);
my $distDir = dirname($FindBin::Bin);
unless ([File::Spec->splitdir($distDir)]->[-1] eq "YATT") {
  plan skip_all => "This test only works when \$distDir ends with 'YATT'";
}

use_ok('YATT::Lite::Test::LangServerClient');

my $server = untaint_any("$distDir/Lite/LanguageServer.pm");

my $TMP = untaint_any(tempdir(CLEANUP => $ENV{NO_CLEANUP} ? 0 : 1));
END { chdir('/') }

#
# $TMP/parent/app.psgi      <- planted above the workspace
# $TMP/parent/ws/index.yatt <- the workspace
#
my $parent = "$TMP/parent";
my $ws = "$parent/ws";
my $marker = "$TMP/parent-app-executed";
make_path($ws);

MY->mkfile_may_wait("$ws/index.yatt", <<'END');
<!yatt:args>
<yatt:foo/>

<!yatt:widget foo>
FOO
END

MY->mkfile_may_wait("$parent/app.psgi", <<"END");
# -*- perl -*-
use strict;
use warnings;
use FindBin;
open my \$fh, '>>', q{$marker} or die \$!; print \$fh "executed\\n"; close \$fh;
use YATT::Lite::WebMVC0::SiteApp -as_base;
{
  my \$SITE = MY->load_factory_for_psgi
    (\$0, app_ns => 'TestLsStopAtParentApp', doc_root => "\$FindBin::Bin/ws");
  if (\$SITE->want_object) { return \$SITE } else { return \$SITE->to_app }
}
END

sub uri_of { "file://$_[0]" }
sub result_of { my ($m) = @_; $m ? $m->{result} : undef }
sub doc_pos {
  my ($uri, $line, $col) = @_;
  +{textDocument => {uri => $uri}, position => {line => $line, character => $col}};
}

my $index = "$ws/index.yatt";
my $index_uri = uri_of($index);

#========================================
subtest "rootUri = ws: the parent's app.psgi is not executed", sub {
  my $cl = YATT::Lite::Test::LangServerClient->new
    (server => $server, timeout => $TIMEOUT);
  ok $cl->pid, "server spawned";

  my $init = $cl->call(initialize => {rootUri => uri_of($ws), capabilities => {}});
  ok result_of($init), "initialize answered" or diag explain $init;
  ok !-e $marker, "parent/app.psgi was NOT executed on initialize";

  # The workspace still works as a bare template dir.
  $cl->notify(initialized => {});
  $cl->notify('textDocument/didOpen', {
    textDocument => {uri => $index_uri, languageId => 'yatt', version => 1
                     , text => "<!yatt:args>\n<yatt:foo/>\n\n<!yatt:widget foo>\nFOO\n"},
  });
  my $def = $cl->call('textDocument/definition', doc_pos($index_uri, 1, 6));
  ok $def, "definition answered";
  is result_of($def)->{range}{start}{line}, 3, "widget foo is resolved in the default site";
  ok !-e $marker, "parent/app.psgi still not executed after requests";

  my ($sd, $code) = $cl->shutdown;
  is $code, 0, "exit code 0";
};

#========================================
subtest "rootUri = parent: its own app.psgi is executed (sanity)", sub {
  my $cl = YATT::Lite::Test::LangServerClient->new
    (server => $server, timeout => $TIMEOUT);
  ok $cl->pid, "server spawned";

  my $init = $cl->call(initialize => {rootUri => uri_of($parent), capabilities => {}});
  ok result_of($init), "initialize answered" or diag explain $init;
  ok -e $marker, "parent/app.psgi WAS executed when parent is the workspace";

  my ($sd, $code) = $cl->shutdown;
  is $code, 0, "exit code 0";
};

done_testing();
