#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#
# GH-262: base+widget-use の循環参照(foo が index を <!yatt:base> で継承し、
# index が foo の widget を使う)は従来から正当なコードであり、
# どちらのファイルへ先にアクセスしても動かなければならない。
#
# declare_base が宣言時に base を eager にコンパイルすると、宣言側テンプレートが
# cached_in の dict 登録前(Util.pm:210)のうちに base の cgen から再 lookup され、
# 同一ファイルの Template が二重 create されて EntNS confliction になる。
#
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::Kantan;
use File::Temp qw/tempdir/;

use Plack::Test;
use HTTP::Request::Common;

use YATT::t::t_preload; # To make Devel::Cover happy.
use YATT::Lite::WebMVC0::SiteApp;
use YATT::Lite::Util::File qw/mkfile_may_wait/;

my $tempdir = tempdir(CLEANUP => 1);
END {chdir "/"}
my $testno = 0;

my %tmpl_files = (
  'index.yatt' => <<'END'
<yatt:layout>
  <h2>Hello</h2>
  <yatt:foo:items/>
</yatt:layout>

<!yatt:widget layout>
<html>

<yatt:body/>

</html>
END
  ,
  'foo.yatt' => <<'END'
<!yatt:base file="index.yatt">

<!yatt:args>
<yatt:layout>
  <h2>foo</h2>
  <yatt:items/>
</yatt:layout>

<!yatt:widget items>

<ul>
  <li>A</li>
  <li>B</li>
  <li>C</li>
</ul>
END
);

my $make_app = sub {
  my $app_root = "$tempdir/t" . ++$testno;
  my $docroot = "$app_root/docs";
  YATT::Lite::Util::File->mkfile_may_wait(
    map {("$docroot/$_" => $tmpl_files{$_})} keys %tmpl_files
  );
  my $site = YATT::Lite::WebMVC0::SiteApp->new(
    app_ns => "TestBaseCycle$testno",
    app_root => $app_root,
    doc_root => $docroot,
  );
  Plack::Test->create($site->to_app);
};

describe "case 1: base-declaring side (foo) as the very first request", sub {
  my $test = $make_app->();

  it "should render foo (inherited layout + own items)", sub {
    my $res = $test->request(GET "/foo");
    expect($res->code)->to_be(200);
    expect($res->content)->to_match(qr{<html>.*<h2>foo</h2>.*<li>A</li>.*</html>}s);
  };

  it "should render index too", sub {
    my $res = $test->request(GET "/");
    expect($res->code)->to_be(200);
    expect($res->content)->to_match(qr{<html>.*<h2>Hello</h2>.*<li>A</li>.*</html>}s);
  };
};

describe "case 2 (control): widget-using side (index) first", sub {
  my $test = $make_app->();

  it "should render index", sub {
    my $res = $test->request(GET "/");
    expect($res->code)->to_be(200);
    expect($res->content)->to_match(qr{<html>.*<h2>Hello</h2>.*<li>A</li>.*</html>}s);
  };

  it "should render foo too", sub {
    my $res = $test->request(GET "/foo");
    expect($res->code)->to_be(200);
    expect($res->content)->to_match(qr{<html>.*<h2>foo</h2>.*<li>A</li>.*</html>}s);
  };
};

done_testing();
