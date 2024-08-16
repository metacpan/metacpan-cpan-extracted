#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::Kantan;
use File::Temp qw/tempdir/;

use Plack::Request;
use Plack::Response;
use HTTP::Request::Common;
use HTTP::Message::PSGI;

use YATT::t::t_preload; # To make Devel::Cover happy.
use YATT::Lite::WebMVC0::SiteApp;
use YATT::Lite::Util qw/combination/;
use YATT::Lite::Util::File qw/mkfile/;
use File::Path qw(make_path);
use Cwd;

use YATT::Lite::PSGIEnv;

my $TEMPDIR = tempdir(CLEANUP => 1);
my $CWD = cwd();
my $TESTNO = 0;
my $CT = ["Content-Type", q{text/html; charset="utf-8"}];

my $TODO = $ENV{TEST_TODO};

#----------------------------------------

my $make_dirs = sub {
  my $app_root = "$TEMPDIR/t" . ++$TESTNO;
  my $html_dir = "$app_root/html";

  make_path($html_dir);

  ($app_root, $html_dir);
};

my $make_siteapp = sub {
  my ($app_root, $html_dir, @args) = @_;

  my $site = YATT::Lite::WebMVC0::SiteApp
    ->new(app_ns => "Test$TESTNO"
          , app_root => $app_root
          , doc_root => $html_dir
          , debug_cgen => $ENV{DEBUG}
        );

  wantarray ? ($app_root, $html_dir, $site) : $site;
};

#========================================

{

  describe "yatt:action name arguments...", sub {

    my ($app_root, $html_dir, $site) = $make_siteapp->($make_dirs->());

    MY->mkfile("$html_dir/index.yatt", <<'END');
<h2>Hello</h2>

<!yatt:action foo x y z>

print $CON "action foo: x=$x;y=$y;z=$z";

<!yatt:action "/bar" p q r>
print $CON "action /bar: p=$p;q=$q;r=$r";
END

    describe "action foo x y z, with request /?!foo=1&x=xx&y=yyy&z=zzzz", sub {
      my Env $psgi = (GET "/?!foo=1&x=xx&y=yyy&z=zzzz")->to_psgi;

      it "should pass x, y, z", sub {
        expect($site->call($psgi))->to_be([200, $CT, ["action foo: x=xx;y=yyy;z=zzzz"]]);
      };
    };

    describe "action /bar p q r, with request /bar?p=P&q=Q&r=R", sub {
      my Env $psgi = (GET "/bar?p=P&q=Q&r=R")->to_psgi;

      it "should pass p, q, r", sub {
        expect($site->call($psgi))->to_be([200, $CT, ["action /bar: p=P;q=Q;r=R"]]);
      };
    };


  };
}

#========================================
chdir($CWD);

done_testing();

