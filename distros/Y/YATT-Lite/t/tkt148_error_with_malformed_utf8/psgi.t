#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { local @_ = "$FindBin::Bin/.."; do "$FindBin::Bin/../t_lib.pl" }
#----------------------------------------
use utf8;

use Test::Kantan;
use YATT::t::t_preload; # To make Devel::Cover happy.
use YATT::Lite::WebMVC0::SiteApp;


BEGIN {
  foreach my $req (qw(Plack Plack::Test HTTP::Request::Common)) {
    unless (eval qq{require $req;}) {
      diag("$req is not installed.");
      skip_all();
    }
    $req->import;
  }
}

my $client = do {

  my $app_root = untaint_any($FindBin::Bin);

  my $site = YATT::Lite::WebMVC0::SiteApp->new(
    app_root => $app_root,
    doc_root => "$app_root/public",
    (-d "$app_root/ytmpl" ? (app_base => '@ytmpl') : ()),
    header_charset => 'utf-8',
    tmpl_encoding => 'utf-8',
    output_encoding => 'utf-8',
  );

  Plack::Test->create($site->to_app);
};


describe 'Sanity check to preload CGen class', sub {
  my $res = $client->request(GET "/sanity_check");

  it "should has code == 200", sub {
    expect($res->code)->to_be(200);
  };

  it "should contain Hello World", sub {
    expect($res->content)->to_match(qr/Hello World/);
  };
};


describe 'Truncated (so malformed) UTF-8 error diag from perl', sub {
  my $res = $client->request(GET "/ng1");

  it "should has code == 500", sub {
    expect($res->code)->to_be(500);
  };

  it "should be reported without encoding error", sub {
    my $rc = expect(Encode::decode_utf8($res->content))->to_match(qr!\QCan't use string ("あいうえおかきくけこ&#xE3;!i);
    unless ($rc) {
      diag([CONTENT => Encode::decode_utf8($res->content)]);
    }
  };
};


done_testing();
