#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------
#
# allow_debug_from / is_debug_allowed_ip decide whether the shipped
# error.ytmpl shows the developer trace. Two things went wrong:
#
#  1. guess_client_ip() believed X-Real-IP / X-Client-IP /
#     X-Forwarded-For from anybody, so any client could pretend to be
#     127.0.0.1. Proxy headers are now honoured only when REMOTE_ADDR
#     is listed in the new `trusted_proxies` config, and
#     X-Forwarded-For is read from the right (the hop added by our
#     proxy), skipping trusted hops.
#
#  2. The allow list was compiled as qr{^(?:...)} without a trailing
#     anchor, so 127.0.0.1 matched 127.0.0.100.
#

use Test::More;
use File::Temp qw/tempdir/;
use File::Path qw(make_path);

BEGIN {
  foreach my $req (qw(Plack Plack::Test HTTP::Request::Common)) {
    unless (eval qq{require $req;}) {
      plan skip_all => "$req is not installed.";
    }
    $req->import;
  }
}

use YATT::t::t_preload; # To make Devel::Cover happy.
use YATT::Lite::WebMVC0::SiteApp;
use YATT::Lite::Util::File qw/mkfile_may_wait/;

my $TMP = tempdir(CLEANUP => $ENV{NO_CLEANUP} ? 0 : 1);
END { chdir('/') }

my $ATTACKER = '203.0.113.9';
my $PROXY = '10.0.0.1';
my $PROXY2 = '10.0.0.2';

my $i = 0;
my $make_site = sub {
  my (%opts) = @_;
  ++$i;
  my $app_root = "$TMP/app$i";
  my $html = "$app_root/html";
  make_path($html, "$app_root/ytmpl");

  # Same gate as the shipped ytmpl/error.ytmpl, minimal bodies.
  MY->mkfile_may_wait("$app_root/ytmpl/error.ytmpl", <<'END');
<!yatt:args err>
<yatt:if "&yatt:is_debug_allowed_ip();">TRACE: &yatt:err:reason();<:yatt:else/>PUBLIC: &yatt:err:reason();</yatt:if>
END

  # A runtime error -> error.ytmpl. (A compile error would report a
  # different reason from the second request on.)
  MY->mkfile_may_wait("$html/varerr.yatt", qq{<?perl die "boom at runtime\\n"?>\n});

  MY->mkfile_may_wait("$html/check.yatt", <<'END');
<!yatt:args ip>
&yatt:if(:is_debug_allowed_ip(:ip),yes,no);
<!yatt:page me>
&yatt:if(:is_debug_allowed_ip(),yes,no);
END

  YATT::Lite::WebMVC0::SiteApp
      ->new(app_ns => "TestDebugAllowed$i"
            , app_root => $app_root, doc_root => $html, app_base => q{@ytmpl}
            , debug_cgen => $ENV{DEBUG}, %opts);
};

# Plack::Test sets REMOTE_ADDR to 127.0.0.1; the wrapper lets each
# request choose its peer address.
sub app_from {
  my ($site, $remote_addr) = @_;
  my $app = $site->to_app;
  sub {
    my ($env) = @_;
    $env->{REMOTE_ADDR} = $remote_addr;
    $app->($env);
  };
}

sub body_of {
  my ($site, $remote_addr, @req) = @_;
  my $res;
  test_psgi app_from($site, $remote_addr), sub {
    my ($cb) = @_;
    $res = $cb->(GET @req);
  };
  $res;
}

#========================================
subtest "guess_client_ip without trusted_proxies: REMOTE_ADDR only", sub {
  my $site = $make_site->();
  my %base = (REMOTE_ADDR => $ATTACKER);

  is $site->guess_client_ip({%base}), $ATTACKER, "plain";
  is $site->guess_client_ip({%base, HTTP_X_REAL_IP => '127.0.0.1'})
    , $ATTACKER, "X-Real-IP is ignored";
  is $site->guess_client_ip({%base, HTTP_X_CLIENT_IP => '127.0.0.1'})
    , $ATTACKER, "X-Client-IP is ignored";
  is $site->guess_client_ip({%base, HTTP_X_FORWARDED_FOR => '127.0.0.1'})
    , $ATTACKER, "X-Forwarded-For is ignored";
  is $site->guess_client_ip({%base, HTTP_X_REAL_IP => '127.0.0.1'
                             , HTTP_X_CLIENT_IP => '127.0.0.1'
                             , HTTP_X_FORWARDED_FOR => '127.0.0.1'})
    , $ATTACKER, "all three are ignored";
};

#========================================
subtest "guess_client_ip with trusted_proxies", sub {
  my $site = $make_site->(trusted_proxies => [$PROXY, $PROXY2]);

  # Peer is not a trusted proxy: headers are ignored.
  is $site->guess_client_ip({REMOTE_ADDR => $ATTACKER
                             , HTTP_X_REAL_IP => '127.0.0.1'
                             , HTTP_X_FORWARDED_FOR => '127.0.0.1'})
    , $ATTACKER, "untrusted peer: headers ignored";

  # Peer is a trusted proxy.
  my %via = (REMOTE_ADDR => $PROXY);
  is $site->guess_client_ip({%via}), $PROXY, "proxy without headers: itself";
  is $site->guess_client_ip({%via, HTTP_X_REAL_IP => $ATTACKER})
    , $ATTACKER, "X-Real-IP";
  is $site->guess_client_ip({%via, HTTP_X_CLIENT_IP => $ATTACKER})
    , $ATTACKER, "X-Client-IP";
  is $site->guess_client_ip({%via, HTTP_X_REAL_IP => $ATTACKER
                             , HTTP_X_CLIENT_IP => '127.0.0.1'
                             , HTTP_X_FORWARDED_FOR => '127.0.0.1'})
    , $ATTACKER, "X-Real-IP wins";

  is $site->guess_client_ip({%via, HTTP_X_FORWARDED_FOR => $ATTACKER})
    , $ATTACKER, "X-Forwarded-For, single";
  is $site->guess_client_ip({%via, HTTP_X_FORWARDED_FOR => "$ATTACKER, $PROXY2"})
    , $ATTACKER, "X-Forwarded-For: rightmost untrusted hop";
  is $site->guess_client_ip({%via, HTTP_X_FORWARDED_FOR => "127.0.0.1, $ATTACKER, $PROXY2"})
    , $ATTACKER, "X-Forwarded-For: a value planted by the client (leftmost) is not used";
  is $site->guess_client_ip({%via, HTTP_X_FORWARDED_FOR => " 127.0.0.1 ,$ATTACKER , $PROXY2 "})
    , $ATTACKER, "X-Forwarded-For: whitespace";
  is $site->guess_client_ip({%via, HTTP_X_FORWARDED_FOR => $PROXY2})
    , $PROXY, "X-Forwarded-For: only trusted hops -> REMOTE_ADDR";
  is $site->guess_client_ip({%via, HTTP_X_FORWARDED_FOR => ''})
    , $PROXY, "X-Forwarded-For: empty -> REMOTE_ADDR";

  my $one = $make_site->(trusted_proxies => $PROXY);
  is $one->guess_client_ip({%via, HTTP_X_REAL_IP => $ATTACKER})
    , $ATTACKER, "trusted_proxies given as a scalar";
  is $one->guess_client_ip({REMOTE_ADDR => "$PROXY.1", HTTP_X_REAL_IP => $ATTACKER})
    , "$PROXY.1", "trusted_proxies is matched exactly, not as a prefix";
};

#========================================
subtest "is_debug_allowed_ip matches the whole address", sub {
  my $site = $make_site->();
  ok $site->is_debug_allowed_ip('127.0.0.1'), "default: 127.0.0.1";
  ok $site->is_debug_allowed_ip('::1'), "default: ::1";
  ok !$site->is_debug_allowed_ip('127.0.0.100'), "127.0.0.100 is not 127.0.0.1";
  ok !$site->is_debug_allowed_ip('127.0.0.1.1'), "127.0.0.1.1";
  ok !$site->is_debug_allowed_ip("127.0.0.1\n"), "trailing newline";
  ok !$site->is_debug_allowed_ip('0127.0.0.1'), "leading junk";
  ok !$site->is_debug_allowed_ip('::10'), "::10 is not ::1";
  ok !$site->is_debug_allowed_ip(''), "empty";

  my $conf = $make_site->(allow_debug_from => ['192.168.1.5', '10.0.0.0']);
  ok $conf->is_debug_allowed_ip('192.168.1.5'), "configured";
  ok !$conf->is_debug_allowed_ip('192.168.1.50'), "configured, longer";
  ok $conf->is_debug_allowed_ip('10.0.0.0'), "configured 2nd";
  ok !$conf->is_debug_allowed_ip('10.0.0.01'), "configured 2nd, longer";
  ok !$conf->is_debug_allowed_ip('127.0.0.1'), "default is replaced, not merged";
};

#========================================
subtest "is_debug_allowed(\$env) (used by runas_fcgi)", sub {
  my $unset = $make_site->();
  ok !$unset->is_debug_allowed({REMOTE_ADDR => '127.0.0.1'})
    , "allow_debug_from unset: never (as before)";

  my $site = $make_site->(allow_debug_from => '127.0.0.1');
  ok $site->is_debug_allowed({REMOTE_ADDR => '127.0.0.1'}), "loopback";
  ok !$site->is_debug_allowed({REMOTE_ADDR => $ATTACKER
                               , HTTP_X_REAL_IP => '127.0.0.1'})
    , "spoofed X-Real-IP";
  ok !$site->is_debug_allowed({REMOTE_ADDR => '127.0.0.100'}), "127.0.0.100";

  my $proxied = $make_site->(allow_debug_from => '127.0.0.1'
                             , trusted_proxies => $PROXY);
  ok $proxied->is_debug_allowed({REMOTE_ADDR => $PROXY
                                 , HTTP_X_REAL_IP => '127.0.0.1'})
    , "via trusted proxy";
  ok !$proxied->is_debug_allowed({REMOTE_ADDR => $ATTACKER
                                  , HTTP_X_REAL_IP => '127.0.0.1'})
    , "not via the proxy";
};

#========================================
subtest "error.ytmpl: the trace is only for the real loopback client", sub {
  my $site = $make_site->();

  my $res = body_of($site, '127.0.0.1', '/varerr.yatt');
  is $res->code, 500, "status 500";
  like $res->content, qr/^TRACE: boom at runtime/, "loopback sees the trace";

  $res = body_of($site, $ATTACKER, '/varerr.yatt');
  is $res->code, 500, "status 500";
  like $res->content, qr/^PUBLIC: boom at runtime/, "remote client sees the public page";

  # F5: the exploit
  foreach my $hdr (qw(X-Real-IP X-Client-IP X-Forwarded-For)) {
    $res = body_of($site, $ATTACKER, '/varerr.yatt', $hdr => '127.0.0.1');
    like $res->content, qr/^PUBLIC: /, "$hdr: 127.0.0.1 from a remote client does not unlock the trace";
  }

  $res = body_of($site, '127.0.0.100', '/varerr.yatt');
  like $res->content, qr/^PUBLIC: /, "127.0.0.100 is not allowed";
};

#========================================
subtest "error.ytmpl behind a trusted proxy", sub {
  my $site = $make_site->(trusted_proxies => $PROXY);

  my $res = body_of($site, $PROXY, '/varerr.yatt', 'X-Real-IP' => '127.0.0.1');
  like $res->content, qr/^TRACE: /, "proxy says loopback: trace";

  $res = body_of($site, $PROXY, '/varerr.yatt', 'X-Forwarded-For' => '127.0.0.1');
  like $res->content, qr/^TRACE: /, "X-Forwarded-For from the proxy: trace";

  $res = body_of($site, $PROXY, '/varerr.yatt', 'X-Forwarded-For' => "127.0.0.1, $ATTACKER");
  like $res->content, qr/^PUBLIC: /, "client-planted 127.0.0.1 behind the real hop: public";

  $res = body_of($site, $PROXY, '/varerr.yatt');
  like $res->content, qr/^PUBLIC: /, "proxy itself is not in allow_debug_from";

  $res = body_of($site, $ATTACKER, '/varerr.yatt', 'X-Real-IP' => '127.0.0.1');
  like $res->content, qr/^PUBLIC: /, "not via the proxy: headers ignored";
};

#========================================
subtest "&yatt:is_debug_allowed_ip() entity", sub {
  my $site = $make_site->();

  my $res = body_of($site, '127.0.0.1', '/check.yatt?~~=me');
  like $res->content, qr/^yes/, "no argument: loopback";

  $res = body_of($site, $ATTACKER, '/check.yatt?~~=me', 'X-Real-IP' => '127.0.0.1');
  like $res->content, qr/^no/, "no argument: spoofed header";

  $res = body_of($site, $ATTACKER, '/check.yatt?ip=127.0.0.1');
  like $res->content, qr/^yes/, "explicit argument is matched as given";

  $res = body_of($site, '127.0.0.1', '/check.yatt?ip=127.0.0.100');
  like $res->content, qr/^no/, "explicit 127.0.0.100";

  $res = body_of($site, '127.0.0.1', '/check.yatt?ip=255.255.255.255');
  like $res->content, qr/^no/, "explicit 255.255.255.255 (samples/basic/9)";
};

done_testing();
