#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use utf8;
use Test::More;
use File::Temp qw(tempdir);
use autodie qw(mkdir);

use YATT::t::t_preload; # To make Devel::Cover happy.

use YATT::Lite::Util qw(catch untaint_any);
use YATT::Lite::Util::File qw(mkfile_may_wait);

BEGIN {
  foreach my $req (qw(Plack Plack::Test Plack::Response HTTP::Request::Common
                      Hash::MultiValue)) {
    unless (eval qq{require $req;}) {
      plan skip_all => "$req is not installed."; exit;
    }
  }
}

use_ok('YATT::Lite::Site');
use_ok('YATT::Lite::Response');
use_ok('YATT::Lite::Site::Registry');
require YATT::Lite::Factory;
require YATT::Lite::WebMVC0::SiteApp;

my $TMP = tempdir(CLEANUP => $ENV{NO_CLEANUP} ? 0 : 1);
END {
  chdir('/');
}

#========================================
# Class hierarchy: Site is the public facade, parent of Factory.
#========================================
{
  ok(YATT::Lite::Factory->isa('YATT::Lite::Site')
     , "Factory isa YATT::Lite::Site");
  ok(YATT::Lite::WebMVC0::SiteApp->isa('YATT::Lite::Site')
     , "SiteApp isa YATT::Lite::Site (SiteApp = Site + PSGI adapter)");
}

#========================================
# Fixture: app1 (has app.psgi), app2 (for Registry), plain dirs (no app.psgi)
#========================================
my $app1 = untaint_any("$TMP/app1");
{
  MY->mkfile_may_wait
    ("$app1/app.psgi", <<'END'
# -*- perl -*-
use strict;
use warnings;
use FindBin;
use YATT::Lite::WebMVC0::SiteApp -as_base;
{
  my $SITE = MY->load_factory_for_psgi
    ($0
     , app_ns => 'TestSiteFacadeApp1'
     , doc_root => "$FindBin::Bin/public"
     , header_charset => 'utf-8'
     , tmpl_encoding => 'utf-8'
     , output_encoding => 'utf-8'
    );
  if ($SITE->want_object) {
    return $SITE;
  } else {
    return $SITE->to_app;
  }
}
END

     , "$app1/public/hello.yatt", <<'END'
<!yatt:args name>
<h2>Hello &yatt:name;!</h2>
END

     , "$app1/public/index.yatt", <<'END'
<!yatt:args title="text?Untitled">
<h1>&yatt:title;</h1>
END

     , "$app1/public/die.yatt", <<'END'
<!yatt:args>
<?perl die "boom!\n"?>
END

     , "$app1/public/sub/inner.yatt", <<'END'
<!yatt:args>
inner page
END

     , "$app1/extra/outer.yatt", <<'END'
<!yatt:args>
outer page
END
    );
}

my $app2 = untaint_any("$TMP/app2");
{
  MY->mkfile_may_wait
    ("$app2/app.psgi", <<'END'
# -*- perl -*-
use strict;
use warnings;
use FindBin;
use YATT::Lite::WebMVC0::SiteApp -as_base;
{
  my $SITE = MY->load_factory_for_psgi
    ($0
     , app_ns => 'TestSiteFacadeApp2'
     , doc_root => "$FindBin::Bin/public"
    );
  if ($SITE->want_object) {
    return $SITE;
  } else {
    return $SITE->to_app;
  }
}
END

     , "$app2/public/hi.yatt", <<'END'
<!yatt:args>
app2 hi
END

     , "$app2/public/sub2/deep.yatt", <<'END'
<!yatt:args>
app2 deep
END
    );
}

my $plain = untaint_any("$TMP/plain");
my $plain2 = untaint_any("$TMP/plain2");
{
  MY->mkfile_may_wait
    ("$plain/hello.yatt", <<'END'
<!yatt:args name>
<h2>Hello &yatt:name;!</h2>
END

     , "$plain2/hello.yatt", <<'END'
<!yatt:args name>
plain2 &yatt:name;
END
    );
}

#========================================
# YATT::Lite::Response (standalone)
#========================================
{
  my $r = YATT::Lite::Response->new
    (status => 302, headers => ['Location' => '/foo'], body => ['moved']);
  is $r->status, 302, "Response->status";
  ok !$r->is_success, "302 is not is_success";
  is scalar($r->header('Location')), '/foo', "Response->header(name)";
  is scalar($r->header('location')), '/foo', "header lookup is case-insensitive";
  is $r->content, 'moved', "Response->content";

  my $ok = YATT::Lite::Response->new
    (status => 200, headers => [], body => ['a', 'b']);
  ok $ok->is_success, "200 is is_success";
  is $ok->content, 'ab', "content joins body chunks";
}

#========================================
# Site->load : upward search of app.psgi
#========================================
my $site = do {
  my $s = YATT::Lite::Site->load(dir => "$app1/public/sub");
  isa_ok($s, 'YATT::Lite::Site', 'Site->load result');
  isa_ok($s, 'YATT::Lite::WebMVC0::SiteApp', 'Site->load result');
  $s;
};

{
  my $err = catch { YATT::Lite::Site->load(dir => $plain) };
  like $err, qr/Can't find factory script/
    , "Site->load dies when no app.psgi is found";
}

{
  # Like Node's require.cache: one factory script = one site object per
  # process (a second raw load would collide on app_ns anyway).
  my $again = YATT::Lite::Site->load(dir => "$app1/public");
  is $again, $site, "Site->load caches per factory script";
}

#========================================
# Site->load_or_default : fallback SiteApp with auto-uniquified app_ns
#========================================
my $plain_site;
{
  $plain_site = YATT::Lite::Site->load_or_default(dir => $plain);
  isa_ok($plain_site, 'YATT::Lite::Site', 'load_or_default result');

  my $p2 = YATT::Lite::Site->load_or_default(dir => $plain2);
  isnt($plain_site->cget('app_ns'), $p2->cget('app_ns')
       , "app_ns is auto-uniquified between default sites");

  my $res = $plain_site->render_file("$plain/hello.yatt", {name => 'plain'});
  like $res->content, qr/Hello plain!/, "default site can render_file";

  my $res2 = $p2->render_file("$plain2/hello.yatt", {name => 'x'});
  like $res2->content, qr/plain2 x/, "second default site works too";
}

#========================================
# resolve_file : location-based under doc_root, physical fallback outside
#========================================
{
  my ($dh, $name) = $site->resolve_file("$app1/public/hello.yatt");
  is $name, 'hello.yatt', "resolve_file returns basename";
  is $dh, $site->get_lochandler('/')
    , "file under doc_root resolves via location '/'";

  my ($dh2, $name2) = $site->resolve_file("$app1/public/sub/inner.yatt");
  is $name2, 'inner.yatt', "nested basename";
  is $dh2, $site->get_lochandler('/sub')
    , "nested file resolves via location '/sub'";

  my ($dh3, $name3) = $site->resolve_file("$app1/extra/outer.yatt");
  is $name3, 'outer.yatt', "outside basename";
  is $dh3, $site->get_dirhandler("$app1/extra")
    , "file outside doc_root falls back to physical dirhandler";
}

#========================================
# render_file : normal case
#========================================
{
  my $res = $site->render_file("$app1/public/hello.yatt", {name => 'world'});
  isa_ok($res, 'YATT::Lite::Response', 'render_file result');
  is $res->status, 200, "render_file status is 200";
  ok $res->is_success, "render_file is_success";
  like $res->content, qr{<h2>Hello world!</h2>}, "render_file output";

  my $outer = $site->render_file("$app1/extra/outer.yatt", {});
  like $outer->content, qr/outer page/, "render_file works outside doc_root";
}

#========================================
# render_file : error policy
#========================================
{
  # Default (tool style): raw die passes through, not converted to error page.
  my $err = catch { $site->render_file("$app1/public/die.yatt", {}) };
  like $err, qr/boom!/, "render_file default: raw die passes through";
  ok !UNIVERSAL::isa($err, 'YATT::Lite::Error')
    , "render_file default: error is not wrapped into YATT::Lite::Error";

  # error_style => 'web': error becomes a Response like the web would produce.
  my $res = $site->render_file("$app1/public/die.yatt", {}
			       , error_style => 'web');
  isa_ok($res, 'YATT::Lite::Response', 'render_file error_style=web result');
  ok !$res->is_success, "error_style=web: not is_success";
  is $res->status, 500, "error_style=web: status 500";
  like $res->content, qr/boom!/, "error_style=web: message is in body";
}

{
  ok((not defined $SIG{__DIE__} and not defined $SIG{__WARN__})
     , "no global SIG handlers are leaked after render_file");
}

#========================================
# request : synthesized env goes through the real call($env)
#========================================
{
  my $res = $site->request(GET => '/hello', {name => 'req world'});
  isa_ok($res, 'YATT::Lite::Response', 'request result');
  is $res->status, 200, "request status 200";
  like $res->content, qr/Hello req world!/, "request output";
  like scalar($res->header('Content-Type')), qr{text/html}
    , "request has Content-Type header";

  my $utf8 = $site->request(GET => '/hello', {name => "世界"});
  like $utf8->content, qr/Hello 世界!/, "request roundtrips utf8 params";

  my $posted = $site->request(POST => '/hello', {name => 'posted'});
  like $posted->content, qr/Hello posted!/, "POST body params work";

  my $default = $site->request(GET => '/index');
  like $default->content, qr{<h1>Untitled</h1>}, "request without args";

  my $res404 = $site->request(GET => '/no_such');
  ok !$res404->is_success, "404 is not is_success";
  is $res404->status, 404, "missing page => 404";
}

#========================================
# request == real PSGI roundtrip
#========================================
{
  my $client = Plack::Test->create($site->to_app);
  my $psgi_res = $client->request(HTTP::Request::Common::GET('/hello?name=abc'));
  my $facade = $site->request(GET => '/hello', {name => 'abc'});
  is $facade->status, $psgi_res->code
    , "request status == real PSGI roundtrip";
  is $facade->content, $psgi_res->decoded_content
    , "request body == real PSGI roundtrip";
}

#========================================
# Site::Registry : per-app-root caching for multi-site tools
#========================================
{
  my $reg = YATT::Lite::Site::Registry->new;
  my $s1 = $reg->site_for("$app2/public/hi.yatt");
  isa_ok($s1, 'YATT::Lite::Site', 'site_for result');
  my $s2 = $reg->site_for("$app2/public/sub2/deep.yatt");
  is $s1, $s2, "same app root => same cached site";

  my $res = $s1->render_file("$app2/public/hi.yatt", {});
  like $res->content, qr/app2 hi/, "registry site can render_file";

  my $s3 = $reg->site_for("$plain/hello.yatt");
  isa_ok($s3, 'YATT::Lite::Site', 'site_for falls back to default site');
  is $reg->site_for("$plain/hello.yatt"), $s3, "plain dir is cached too";
  isnt($s3, $s1, "different roots => different sites");
}

done_testing();
