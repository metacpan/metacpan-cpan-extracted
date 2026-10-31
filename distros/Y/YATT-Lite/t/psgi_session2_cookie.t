#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------
#
# YATT::Lite::WebMVC0::Partial::Session2:
#  - the session id from the cookie is validated before it reaches the
#    store (with Plack::Session::Store::File an unvalidated id is a file
#    path: "../../x" could unlink or Storable-load arbitrary files),
#  - the session cookie carries HttpOnly and SameSite=Lax by default,
#  - Secure is set whenever the request came over TLS, not only when
#    the CGI-style HTTPS variable is present.
#

use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);

BEGIN {
  foreach my $req (qw(Plack Plack::Test HTTP::Request::Common
                      Plack::Middleware::Session Plack::Session::Store::File)) {
    unless (eval qq{require $req;}) {
      plan skip_all => "$req is not installed.";
    }
    $req->import;
  }
}

use YATT::t::t_preload; # To make Devel::Cover happy.
use YATT::Lite::Util::File qw(mkfile_may_wait);

use Plack::Session::State::Cookie ();
{
  package t_sess2_app;
  use mro 'c3';
  use YATT::Lite::WebMVC0::SiteApp -as_base;
  use YATT::Lite::WebMVC0::Partial::Session2 -as_base;
}

my $TMP = tempdir(CLEANUP => $ENV{NO_CLEANUP} ? 0 : 1);
END { chdir('/') }

my $PAGE = <<'END';
<!yatt:args>
&yatt:session_start();
&yatt:session_set(hello,world);
id=&yatt:session_id();

<!yatt:page show>
sid cookie=&yatt:session_state_id();
exists=&yatt:if(:session_state_exists(),yes,no);
&yatt:session_start();
hello=&yatt:session_get(hello);

<!yatt:page logout>
&yatt:session_expire();
expired
END

my $i = 0;
my $make_site = sub {
  my (%opts) = @_;
  ++$i;
  my $approot = "$TMP/app$i";
  my $docroot = "$approot/docs";
  MY->mkfile_may_wait("$docroot/index.yatt", $PAGE);
  my $sessdir = "$approot/sess";
  make_path($sessdir);
  my $site = t_sess2_app->new(
    app_ns => "MyYATTSess2Cookie$i"
    , app_root => $approot
    , doc_root => $docroot
    , session_store => [File => dir => $sessdir]
    , %opts
  );
  ($site, $sessdir, $approot);
};

my $cookie_of = sub {
  my ($res) = @_;
  my @set = $res->header('Set-Cookie');
  my ($sid) = grep {/^plack_session=/} @set;
  $sid;
};

#========================================
subtest "cookie attributes with the default state", sub {
  my ($site) = $make_site->();
  my $test = Plack::Test->create($site->to_app);

  my $res = $test->request(GET "/");
  is $res->code, 200, "GET / (session_start)";
  my $ck = $cookie_of->($res);
  ok $ck, "Set-Cookie: plack_session is emitted";
  like $ck, qr/; HttpOnly/i, "HttpOnly by default";
  like $ck, qr/; SameSite=Lax/i, "SameSite=Lax by default";
  unlike $ck, qr/; secure/i, "no Secure over plain http";
  like $ck, qr/^plack_session=[0-9a-f]{40};/, "40 hex id";

  # logout: expire cookie keeps the same attributes.
  my ($sid) = $ck =~ /^plack_session=([0-9a-f]{40})/;
  $res = $test->request(GET "/?~~=logout", Cookie => "plack_session=$sid");
  is $res->code, 200, "logout";
  $ck = $cookie_of->($res);
  ok $ck, "expire cookie is emitted";
  like $ck, qr/; HttpOnly/i, "expire cookie: HttpOnly";
  like $ck, qr/; SameSite=Lax/i, "expire cookie: SameSite=Lax";
  like $ck, qr/; expires=/i, "expire cookie: expires";
};

#========================================
subtest "Secure is derived from the request scheme", sub {
  my ($site) = $make_site->();
  my $app = $site->to_app;

  my $call = sub {
    my (%env) = @_;
    my $req = GET "/";
    my $psgi_env = $req->to_psgi;
    $psgi_env->{$_} = $env{$_} for keys %env;
    my $res = HTTP::Response->from_psgi($app->($psgi_env));
    $cookie_of->($res);
  };

  unlike $call->(), qr/; secure/i, "http: no Secure";
  like $call->('psgi.url_scheme' => 'https'), qr/; secure/i
    , "psgi.url_scheme=https: Secure";
  like $call->(HTTP_X_FORWARDED_PROTO => 'https'), qr/; secure/i
    , "X-Forwarded-Proto: https: Secure";
  like $call->(HTTPS => 'on'), qr/; secure/i, "HTTPS=on: Secure";
  unlike $call->(HTTPS => 'off'), qr/; secure/i, "HTTPS=off: no Secure";
};

#========================================
subtest "explicit session_state wins over the defaults", sub {
  require Plack::Session::State::Cookie;
  my ($site) = $make_site->(
    session_state => Plack::Session::State::Cookie->new(
      httponly => 0, samesite => 'Strict', session_key => 'sid',
    ),
  );
  my $test = Plack::Test->create($site->to_app);
  my $res = $test->request(GET "/");
  my ($ck) = grep {/^sid=/} $res->header('Set-Cookie');
  ok $ck, "Set-Cookie: sid";
  unlike $ck, qr/; HttpOnly/i, "httponly => 0 is respected";
  like $ck, qr/; SameSite=Strict/i, "samesite => Strict is respected";
};

#========================================
subtest "a crafted session id never reaches the file store", sub {
  my ($site, $sessdir, $approot) = $make_site->();
  my $test = Plack::Test->create($site->to_app);

  # A file outside the session dir, reachable by "../" from it.
  my $victim = "$approot/victim.txt";
  MY->mkfile_may_wait($victim, "do not delete me\n");
  my $traversal = "../victim.txt";

  foreach my $page (qw(logout show), '') {
    my $url = $page ? "/?~~=$page" : "/";
    my $res = $test->request(GET $url, Cookie => "plack_session=$traversal");
    ok $res->code == 200, "$url with traversal cookie: 200 (got ".$res->code.")";
    ok -e $victim, "$url: file outside the session dir still exists";
    if ($page eq 'show') {
      like $res->content, qr/^sid cookie=$/m, "crafted id is reported as no cookie";
      like $res->content, qr/^exists=no$/m, "session_state_exists is false";
    }
  }

  # Other non-conforming ids are ignored too (no crash, fresh session).
  foreach my $bad ("x" x 40, "0" x 39, "0" x 41, "../../etc/passwd", "a b") {
    my $res = $test->request(GET "/?~~=show", Cookie => "plack_session=$bad");
    is $res->code, 200, "bad id '$bad' -> 200";
    like $res->content, qr/^sid cookie=$/m, "bad id '$bad' -> no cookie";
  }

  # Sanity: a real id round-trips.
  my $res = $test->request(GET "/");
  my ($sid) = $cookie_of->($res) =~ /^plack_session=([0-9a-f]{40})/;
  ok $sid, "got a real sid";
  $res = $test->request(GET "/?~~=show", Cookie => "plack_session=$sid");
  like $res->content, qr/^sid cookie=$sid$/m, "real id is accepted";
  like $res->content, qr/^hello=world$/m, "session data round-trips via the file store";
  ok -e "$sessdir/$sid", "session file exists";

  # logout removes exactly that file.
  $res = $test->request(GET "/?~~=logout", Cookie => "plack_session=$sid");
  ok !-e "$sessdir/$sid", "session file is removed on logout";
  ok -e $victim, "victim file still exists";
};

done_testing();
