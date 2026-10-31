#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------
#
# YATT::Lite::WebMVC0::Partial::Session (CGI::Session based):
#  - the SID cookie carries HttpOnly and SameSite=Lax, and Secure when
#    the request came over TLS,
#  - session ids come from the OS CSPRNG (40 hex chars), not from
#    CGI::Session's id:md5 (md5 of pid, time and rand()),
#  - the CSRF token is a random value kept in the session, not the SID,
#  - a cookie value that is not a plain token is treated as no cookie.
#

use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);

BEGIN {
  foreach my $req (qw(Plack Plack::Test HTTP::Request::Common CGI::Session)) {
    unless (eval qq{require $req;}) {
      plan skip_all => "$req is not installed.";
    }
    $req->import;
  }
}

use YATT::t::t_preload; # To make Devel::Cover happy.
use YATT::Lite::Util::File qw(mkfile_may_wait);
use YATT::Lite::Util ();

{
  package t_sess_app;
  use YATT::Lite::WebMVC0::SiteApp -as_base;
  use YATT::Lite::WebMVC0::Partial::Session;
}

my $TMP = tempdir(CLEANUP => $ENV{NO_CLEANUP} ? 0 : 1);
END { chdir('/') }

my $PAGE = <<'END';
<!yatt:args>
&yatt:session_start();
sid=&yatt:sess_id();
csrf=&yatt:session_csrf_token();
&yatt:csrf_token_input();

<!yatt:page show>
sid=&yatt:sess_id();
csrf=&yatt:session_csrf_token();
check=&yatt:if(:csrf_token_check(),ok,ng);

<!yatt:page logout>
&yatt:session_delete();
deleted
END

my $RC = <<'END';
use strict;
use YATT::Lite qw/Entity *CON/;
Entity sess_id => sub { my $s = $CON->get_session; $s ? $s->id : '' };
END

my $i = 0;
my $make_site = sub {
  my (%opts) = @_;
  ++$i;
  my $approot = "$TMP/app$i";
  my $docroot = "$approot/docs";
  MY->mkfile_may_wait("$docroot/index.yatt", $PAGE);
  MY->mkfile_may_wait("$docroot/.htyattrc.pl", $RC);
  make_path("$approot/var/tmp");
  my $site = t_sess_app->new(
    app_ns => "MyYATTSessCookie$i"
    , app_root => $approot
    , doc_root => $docroot
    , use_session => 1
    , %opts
  );
  $site;
};

my $cookie_of = sub {
  my ($res, $name) = @_;
  $name //= 'SID';
  my ($ck) = grep {/^\Q$name\E=/} $res->header('Set-Cookie');
  $ck;
};

#========================================
subtest "secure_random_hex", sub {
  my $sub = YATT::Lite::Util->can('secure_random_hex')
    or return fail "YATT::Lite::Util::secure_random_hex is missing";
  my $a = $sub->(20);
  my $b = $sub->(20);
  like $a, qr/^[0-9a-f]{40}$/, "40 hex chars";
  isnt $a, $b, "two calls differ";
};

#========================================
subtest "SID cookie attributes and id format", sub {
  my $site = $make_site->();
  my $test = Plack::Test->create($site->to_app);

  my $res = $test->request(GET "/");
  is $res->code, 200, "GET / (session_start)" or diag $res->content;
  my $ck = $cookie_of->($res);
  ok $ck, "Set-Cookie: SID is emitted" or diag join("\n", $res->header('Set-Cookie'));
  like $ck, qr/; HttpOnly/i, "HttpOnly by default";
  like $ck, qr/; SameSite=Lax/i, "SameSite=Lax by default";
  unlike $ck, qr/; secure/i, "no Secure over plain http";
  like $ck, qr/^SID=[0-9a-f]{40};/, "id is 40 hex chars (not 32 of md5)";

  my ($sid) = $ck =~ /^SID=([0-9a-f]{40})/;
  like $res->content, qr/^sid=$sid$/m, "page sees the same sid";

  # delete: the expiring cookie keeps the attributes.
  $res = $test->request(GET "/?~~=logout", Cookie => "SID=$sid");
  is $res->code, 200, "logout";
  $ck = $cookie_of->($res);
  ok $ck, "expiring cookie is emitted";
  like $ck, qr/; HttpOnly/i, "expiring cookie: HttpOnly";
  like $ck, qr/; SameSite=Lax/i, "expiring cookie: SameSite=Lax";
  like $ck, qr/; expires=/i, "expiring cookie: expires";
};

#========================================
subtest "Secure is derived from the request scheme", sub {
  my $site = $make_site->();
  my $app = $site->to_app;

  my $call = sub {
    my (%env) = @_;
    my $psgi_env = (GET "/")->to_psgi;
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
};

#========================================
subtest "session_config can override cookie attributes", sub {
  my $site = $make_site->(
    session_config => {name => 'MYSID', httponly => 0, samesite => 'Strict', secure => 1},
  );
  my $test = Plack::Test->create($site->to_app);
  my $res = $test->request(GET "/");
  my $ck = $cookie_of->($res, 'MYSID');
  ok $ck, "Set-Cookie: MYSID";
  unlike $ck, qr/; HttpOnly/i, "httponly => 0";
  like $ck, qr/; SameSite=Strict/i, "samesite => Strict";
  like $ck, qr/; secure/i, "secure => 1 even over http";
};

#========================================
subtest "CSRF token is not the session id", sub {
  my $site = $make_site->();
  my $test = Plack::Test->create($site->to_app);

  my $res = $test->request(GET "/");
  my ($sid) = $cookie_of->($res) =~ /^SID=([0-9a-f]{40})/;
  my ($csrf) = $res->content =~ /^csrf=([0-9a-f]+)$/m;
  ok $csrf, "csrf token is printed";
  isnt $csrf, $sid, "csrf token differs from sid";
  like $res->content
    , qr/<input type="hidden" name="--csrftok" value="\Q$csrf\E">/
    , "csrf_token_input prints the token, not the sid";
  unlike $res->content, qr/value="\Q$sid\E"/, "sid is not printed into the form";

  # Stable across requests of the same session.
  $res = $test->request(GET "/?~~=show", Cookie => "SID=$sid");
  like $res->content, qr/^csrf=\Q$csrf\E$/m, "token is stable within the session";
  like $res->content, qr/^check=ng$/m, "check fails without the token";

  $res = $test->request(GET "/?~~=show&--csrftok=$csrf", Cookie => "SID=$sid");
  like $res->content, qr/^check=ok$/m, "check passes with the token";

  $res = $test->request(GET "/?~~=show&--csrftok=$sid", Cookie => "SID=$sid");
  like $res->content, qr/^check=ng$/m, "the sid itself is not accepted as the token";
};

#========================================
subtest "a non-token cookie value is treated as no cookie", sub {
  my $site = $make_site->();
  my $test = Plack::Test->create($site->to_app);

  foreach my $bad ("../../etc/passwd", "a b", "x/y", "\\x", "x" x 129) {
    my $res = $test->request(GET "/?~~=show", Cookie => "SID=$bad");
    is $res->code, 200, "bad SID -> 200" or diag $res->content;
    like $res->content, qr/^sid=$/m, "bad SID -> no session";
  }
};

done_testing();
