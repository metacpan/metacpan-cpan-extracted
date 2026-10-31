#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#
# GH-275: JSON-RPC transport of YATT::Lite::LanguageServer, driven over pipes.
#
#  - frames pipelined in one write (eglot sends didChange + definition
#    back to back) must all be answered without waiting for more input
#  - frames split across writes, frames larger than read_length
#  - bad header / unparsable body must not kill the server
#  - initialize advertises positionEncoding utf-32 when the client offers it
#  - shutdown => null, exit => exit code 0
#
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::More;
use File::Temp qw(tempdir);

use YATT::t::t_preload; # To make Devel::Cover happy.

use YATT::Lite::Util qw(untaint_any read_file);
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
# File::AddInc (used by the modulino) needs the script path to end with
# YATT/Lite/LanguageServer.pm, so no "t/.." in it.
unless ([File::Spec->splitdir($distDir)]->[-1] eq "YATT") {
  plan skip_all => "This test only works when \$distDir ends with 'YATT'";
}

use_ok('YATT::Lite::Test::LangServerClient');

my $server = untaint_any("$distDir/Lite/LanguageServer.pm");

my $TMP = tempdir(CLEANUP => $ENV{NO_CLEANUP} ? 0 : 1);
END {
  chdir('/');
}

#========================================
# Fixture: a bare template dir (no app.psgi)
#========================================
my $root = untaint_any("$TMP/site");
MY->mkfile_may_wait
  ("$root/index.yatt", <<'END'
<!yatt:args>
<yatt:foo/>
<yatt:other:bar/>

<!yatt:widget foo>
FOO
END
   , "$root/other.yatt", <<'END'
<!yatt:widget bar>
BAR
END
  );

sub uri_of { "file://$_[0]" }
sub result_of { my ($m) = @_; $m ? $m->{result} : undef }

my $index = "$root/index.yatt";
my $index_uri = uri_of($index);
my $index_text = read_file($index);

sub doc_pos {
  my ($uri, $line, $col) = @_;
  +{textDocument => {uri => $uri}, position => {line => $line, character => $col}};
}

#========================================
# In-process: uri2localpath must percent-decode (GH-275)
#========================================
{
  require YATT::Lite::LanguageServer::Generic;
  is(YATT::Lite::LanguageServer::Generic->uri2localpath
     ("file:///tmp/a%20b/%E3%81%82.yatt")
     , "/tmp/a b/\xe3\x81\x82.yatt"
     , "uri2localpath percent-decodes (space, non-ascii)");
}

#========================================
# Spawn
#========================================
my $cl = YATT::Lite::Test::LangServerClient->new
  (server => $server, timeout => $TIMEOUT);

ok $cl->pid, "server spawned (pid @{[$cl->pid]})";

#----------------------------------------
# 1. initialize (alone)
#----------------------------------------
{
  my $init = $cl->call(initialize => {
    rootUri => uri_of($root),
    capabilities => {general => {positionEncodings => ['utf-32', 'utf-16']}},
  });
  ok result_of($init), "initialize answered" or diag explain $init;
  is result_of($init)->{capabilities}{positionEncoding}, 'utf-32'
    , "advertises positionEncoding utf-32 when the client offers it";
  ok result_of($init)->{capabilities}{definitionProvider}
    , "definitionProvider";
}

#----------------------------------------
# 2. THE bug: initialized + didOpen + definition in ONE write.
#    eglot--request flushes pending didChange right before a request,
#    so both frames land in the same read.
#----------------------------------------
{
  my $req = $cl->make_request('textDocument/definition'
                              , doc_pos($index_uri, 1, 6)); # <yatt:foo/>
  $cl->send_messages(
    $cl->make_notification(initialized => {}),
    $cl->make_notification('textDocument/didOpen', {
      textDocument => {uri => $index_uri, languageId => 'yatt'
                       , version => 1, text => $index_text},
    }),
    $req,
  );
  my $def = $cl->wait_response($req->{id});
  ok $def, "definition answered although pipelined behind didOpen (GH-275)"
    or diag "no response within $TIMEOUT sec";
  is result_of($def)->{uri}, $index_uri, "same-file widget uri";
  is result_of($def)->{range}{start}{line}, 4, "<!yatt:widget foo> line";
}

#----------------------------------------
# 3. header and body in two writes
#----------------------------------------
{
  my $req = $cl->make_request('textDocument/definition'
                              , doc_pos($index_uri, 2, 12)); # <yatt:other:bar/>
  my ($hdr, $body) = $cl->frame($req) =~ /\A(.*?\r\n\r\n)(.*)\z/s;
  $cl->send_raw($hdr);
  select(undef, undef, undef, 0.2);
  $cl->send_raw($body);
  my $def = $cl->wait_response($req->{id});
  ok $def, "definition answered for a frame split in two writes";
  is result_of($def)->{uri}, uri_of("$root/other.yatt")
    , "<yatt:other:bar> resolves across files";
  is result_of($def)->{range}{start}{line}, 0, "<!yatt:widget bar> line";
}

#----------------------------------------
# 4. a frame larger than read_length (8192): full-document didChange
#----------------------------------------
{
  my $big = $index_text . "<!--#yatt " . ("x" x 20000) . " -->\n";
  my $req = $cl->make_request('textDocument/definition'
                              , doc_pos($index_uri, 1, 6));
  $cl->send_messages(
    $cl->make_notification('textDocument/didChange', {
      textDocument => {uri => $index_uri, version => 2},
      contentChanges => [{text => $big}],
    }),
    $req,
  );
  my $def = $cl->wait_response($req->{id});
  ok $def, "definition answered after a >8192-byte frame";
  is result_of($def)->{range}{start}{line}, 4
    , "definition still resolves after full-document didChange";
}

#----------------------------------------
# 5. header without Content-Length, then unparsable JSON:
#    the server must survive both and answer the next request.
#----------------------------------------
{
  my $req = $cl->make_request('textDocument/hover', doc_pos($index_uri, 1, 6));
  $cl->send_raw("X-Bogus: 1\r\n\r\n"
                . "Content-Length: 3\r\n\r\n{{{"
                . $cl->frame($req));
  my $res = $cl->wait_response($req->{id});
  ok $res, "survives a header without Content-Length and an unparsable body";
}

#----------------------------------------
# 6. shutdown => null, exit => exit code 0
#----------------------------------------
{
  my ($sd, $code) = $cl->shutdown;
  ok $sd && exists $sd->{result} && !defined $sd->{result}
    , "shutdown returns null result";
  is $code, 0, "exit code 0 after shutdown";
}

done_testing();
