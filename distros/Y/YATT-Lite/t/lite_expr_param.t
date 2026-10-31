#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#
# code/expr 型のページ引数は、リクエストパラメータから値を受け取らない (GH-294)。
#
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::More;
use File::Temp qw/tempdir/;

BEGIN {
  foreach my $req (qw(Plack::Test HTTP::Request::Common)) {
    unless (eval qq{require $req;}) {
      plan skip_all => "$req is not installed."; exit;
    }
    $req->import;
  }
}

use YATT::t::t_preload; # To make Devel::Cover happy.
use YATT::Lite::WebMVC0::SiteApp;
use YATT::Lite::Util::File qw/mkfile_may_wait/;

my $tempdir = tempdir(CLEANUP => 1);
END {chdir "/"}

my $docroot = "$tempdir/docs";
YATT::Lite::Util::File->mkfile_may_wait(
  "$docroot/expr.yatt" => <<'END',
<!yatt:args f=expr x>
[&yatt:f();|&yatt:x;]
END
  "$docroot/code.yatt" => <<'END',
<!yatt:args f=[code] x>
[&yatt:f();|&yatt:x;]
END
);

my $site = YATT::Lite::WebMVC0::SiteApp->new(
  app_ns => "TestExprParam",
  app_root => $tempdir,
  doc_root => $docroot,
);
my $client = Plack::Test->create($site->to_app);

foreach my $page (qw(expr code)) {
  my $res = $client->request(GET "/$page?f=CORE::die&x=X");
  is($res->code, 200, "$page: status");
  is($res->content, "[|X]\n", "$page: f is not taken from the request");
}

done_testing();
