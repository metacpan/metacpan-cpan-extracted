#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

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

  my $rootname = untaint_any($FindBin::Bin."/psgi");

  my $site = YATT::Lite::WebMVC0::SiteApp->new(
    app_root => $FindBin::Bin,
    doc_root => "$rootname.d",
  );

  Plack::Test->create($site->to_app);
};


describe 'Sanity check to preload CGen class', sub {
  my $res = $client->request(GET "/empty");

  it "should has code == 200", sub {
    expect($res->code)->to_be(200);
  };

  it "should contain Hello World", sub {
    expect($res->content)->to_match(qr/Hello World/);
  };
};


describe 'Compile error from *.ydo', sub {
  my $res = $client->request(GET "/ng1.ydo");

  it "should has code == 500", sub {
    expect($res->code)->to_be(500);
  };

  it "should contain proper error message", sub {
    expect($res->content)->to_match(qr!Can't locate Hoehoe/Long/Wrong/Missing/Module\.pm!);
  };
};


describe 'When previously failed ydo is accessed again', sub {
  my $res = $client->request(GET "/ng1.ydo");

  it "should has code == 500", sub {
    expect($res->code)->to_be(500);
  };

  it "should return proper error message again", sub {
    expect($res->content)->to_match(qr!Can't locate Hoehoe/Long/Wrong/Missing/Module\.pm!);
  };
};

done_testing();
