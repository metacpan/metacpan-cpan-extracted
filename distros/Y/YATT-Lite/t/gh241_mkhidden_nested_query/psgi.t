#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { local @_ = "$FindBin::Bin/.."; do "$FindBin::Bin/../t_lib.pl" }
#----------------------------------------
use utf8;

use Test::Spec;
use Plack::Test;
use Test::Differences;

use Plack::Util ();

use YATT::t::t_preload; # To make Devel::Cover happy.
use YATT::Lite::WebMVC0::SiteApp; # for debugging

BEGIN {
  foreach my $req (qw(Plack Plack::Test HTTP::Request::Common)) {
    unless (eval qq{require $req;}) {
      diag("$req is not installed.");
      skip_all();
    }
    $req->import;
  }
}

{
  # param_test.yatt prints :param(.foo[]) (an ARRAY) via escape(), which
  # dumps references only with HTDEBUG_DUMP (or in development).
  $ENV{HTDEBUG_DUMP} = 1; # not local: Test::Spec runs the blocks later
  my $app = Plack::Util::load_psgi "$FindBin::Bin/app/app.psgi";
  my $test = Plack::Test->create($app);

  describe ":param(.foo[]), :param(.foo)", sub {
    it "should return same result", sub {
      my $res = $test->request(GET "/param_test?.foo[]=aa&.foo[]=bb");
      eq_or_diff $res->content, <<'END';
[
  &#39;aa&#39;,
  &#39;bb&#39;
]


[
  &#39;aa&#39;,
  &#39;bb&#39;
]

END
    }
  };

  describe ":mkhidden(.bar[]), :mkhidden(.bar)", sub {
    it "should return same result", sub {
      my $res = $test->request(GET "/mkhidden_test?.bar[]=aa&.bar[]=bb");
      eq_or_diff $res->content, <<'END';
<input type="hidden" name=".bar[]" value="aa">
<input type="hidden" name=".bar[]" value="bb">

<input type="hidden" name=".bar[]" value="aa">
<input type="hidden" name=".bar[]" value="bb">
END
    }
  };
}

runtests unless caller;
