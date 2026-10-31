#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------
#
# YATT::Lite::WebMVC0::Partial::StrictIPMatch replaces the literal
# string matching of allow_debug_from / trusted_proxies (the cheap
# default in SiteApp) with real address parsing: CIDR ranges,
# IPv6 normalization and IPv4-mapped IPv6 addresses. It overrides one
# hook, compile_addr_matcher, so both lists benefit.
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
use YATT::Lite::Util qw(catch);
use YATT::Lite::Util::File qw/mkfile_may_wait/;

{
  package t_strict_app;
  use mro 'c3';
  use YATT::Lite::WebMVC0::SiteApp -as_base;
  use YATT::Lite::WebMVC0::Partial::StrictIPMatch -as_base;
}

my $TMP = tempdir(CLEANUP => $ENV{NO_CLEANUP} ? 0 : 1);
END { chdir('/') }

my $i = 0;
my $make_site = sub {
  my (%opts) = @_;
  ++$i;
  my $app_root = "$TMP/app$i";
  my $html = "$app_root/html";
  make_path($html, "$app_root/ytmpl");
  MY->mkfile_may_wait("$app_root/ytmpl/error.ytmpl", <<'END');
<!yatt:args err>
<yatt:if "&yatt:is_debug_allowed_ip();">TRACE: &yatt:err:reason();<:yatt:else/>PUBLIC: &yatt:err:reason();</yatt:if>
END
  MY->mkfile_may_wait("$html/varerr.yatt", qq{<?perl die "boom at runtime\\n"?>\n});

  t_strict_app->new(app_ns => "TestStrictIP$i"
                    , app_root => $app_root, doc_root => $html, app_base => q{@ytmpl}
                    , debug_cgen => $ENV{DEBUG}, %opts);
};

sub body_of {
  my ($site, $remote_addr, @req) = @_;
  my $app = $site->to_app;
  my $res;
  test_psgi sub { my ($env) = @_; $env->{REMOTE_ADDR} = $remote_addr; $app->($env) }
    , sub { my ($cb) = @_; $res = $cb->(GET @req) };
  $res;
}

#========================================
subtest "default allow list (loopback v4/v6)", sub {
  my $site = $make_site->();
  ok $site->is_debug_allowed_ip('127.0.0.1'), "127.0.0.1";
  ok $site->is_debug_allowed_ip('::1'), "::1";
  ok $site->is_debug_allowed_ip('0:0:0:0:0:0:0:1'), "::1 spelled out";
  ok $site->is_debug_allowed_ip('::ffff:127.0.0.1'), "IPv4-mapped loopback";
  ok !$site->is_debug_allowed_ip('127.0.0.100'), "127.0.0.100";
  ok !$site->is_debug_allowed_ip('::2'), "::2";
  ok !$site->is_debug_allowed_ip('garbage'), "not an address";
  ok !$site->is_debug_allowed_ip(''), "empty";
  ok !$site->is_debug_allowed_ip("127.0.0.1\n"), "trailing newline";
};

#========================================
subtest "CIDR and IPv6 in allow_debug_from", sub {
  my $site = $make_site->(allow_debug_from => ['10.0.0.0/8', '2001:db8::/32'
                                               , '::1', '192.168.1.5']);
  ok $site->is_debug_allowed_ip('10.1.2.3'), "10.1.2.3 in 10.0.0.0/8";
  ok $site->is_debug_allowed_ip('10.255.255.255'), "10.255.255.255";
  ok !$site->is_debug_allowed_ip('11.0.0.1'), "11.0.0.1";
  ok !$site->is_debug_allowed_ip('9.255.255.255'), "9.255.255.255";
  ok $site->is_debug_allowed_ip('::ffff:10.1.2.3'), "IPv4-mapped 10.1.2.3";
  ok $site->is_debug_allowed_ip('2001:db8::1'), "2001:db8::1";
  ok $site->is_debug_allowed_ip('2001:DB8:0:0:0:0:0:1'), "uppercase, spelled out";
  ok $site->is_debug_allowed_ip('2001:db8:ffff:ffff:ffff:ffff:ffff:ffff'), "end of /32";
  ok !$site->is_debug_allowed_ip('2001:db9::1'), "2001:db9::1";
  ok $site->is_debug_allowed_ip('::1'), "::1";
  ok $site->is_debug_allowed_ip('192.168.1.5'), "single address";
  ok !$site->is_debug_allowed_ip('192.168.1.50'), "single address, longer";
  ok !$site->is_debug_allowed_ip('127.0.0.1'), "default is replaced";

  my $all = $make_site->(allow_debug_from => '0.0.0.0/0');
  ok $all->is_debug_allowed_ip('203.0.113.9'), "0.0.0.0/0 matches any IPv4";
  ok !$all->is_debug_allowed_ip('2001:db8::1'), "0.0.0.0/0 does not match IPv6";
};

#========================================
subtest "trusted_proxies as CIDR", sub {
  my $site = $make_site->(trusted_proxies => '172.16.0.0/12');
  is $site->guess_client_ip({REMOTE_ADDR => '172.20.0.5', HTTP_X_REAL_IP => '203.0.113.9'})
    , '203.0.113.9', "X-Real-IP via 172.20.0.5";
  is $site->guess_client_ip({REMOTE_ADDR => '172.20.0.5'
                             , HTTP_X_FORWARDED_FOR => '127.0.0.1, 203.0.113.9, 172.31.1.1'})
    , '203.0.113.9', "X-Forwarded-For skips trusted hops in the range";
  is $site->guess_client_ip({REMOTE_ADDR => '172.32.0.1', HTTP_X_REAL_IP => '127.0.0.1'})
    , '172.32.0.1', "172.32.0.1 is outside /12";
};

#========================================
subtest "invalid entries are rejected at configure time", sub {
  foreach my $bad ('10.0.0.0/33', 'example.com', '10.0.0', '::1/129', '10.0.0.0/8/1', '1.2.3.4 ') {
    my $err = catch { $make_site->(allow_debug_from => $bad) };
    like $err, qr/Invalid address or CIDR in allow_debug_from: \Q$bad\E/, "allow_debug_from: '$bad'";
  }
  my $err = catch { $make_site->(trusted_proxies => 'proxy.local') };
  like $err, qr/Invalid address or CIDR in trusted_proxies: proxy\.local/, "trusted_proxies";
};

#========================================
subtest "error.ytmpl through the Partial", sub {
  my $site = $make_site->(allow_debug_from => '10.0.0.0/8');
  like body_of($site, '10.1.2.3', '/varerr.yatt')->content, qr/^TRACE: /, "in range: trace";
  like body_of($site, '11.0.0.1', '/varerr.yatt')->content, qr/^PUBLIC: /, "out of range: public";
  like body_of($site, '11.0.0.1', '/varerr.yatt', 'X-Real-IP' => '10.1.2.3')->content
    , qr/^PUBLIC: /, "spoofed header still ignored";
};

done_testing();
