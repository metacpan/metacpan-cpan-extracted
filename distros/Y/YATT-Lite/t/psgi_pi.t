#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

#use Test::Kantan;
use Test::More;
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

{
  package
    t_call_tester;
  sub new {
    my ($pack, $app) = @_;
    bless [$app], $pack;
  }

  sub psgi_status {
    my ($self, $psgi, $expect_status, $it_should) = @_;
    my $got;
    if (my $err = YATT::Lite::Util::catch {
      $got = $self->[0]->call($psgi);
    }) {
      Test::More::fail("$it_should: $err");
    } else {
      Test::More::is($got->[0], $expect_status, $it_should);
    }
  }
}

my $TEMPDIR = tempdir(CLEANUP => 1);
my $CWD = cwd();
my $TESTNO = 0;
my $CT_error = ["Content-type", q{text/plain; charset=utf-8}];

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

{
  my ($app_root, $html_dir, $site) = $make_siteapp->($make_dirs->());

  my $tester = t_call_tester->new($site);

  MY->mkfile("$app_root/outside.yatt", <<'END');
OUTSIDE
END

  {
    my Env $psgi = (GET my $path = "/../outside.yatt")->to_psgi;

    $tester->psgi_status($psgi, 403, $path);
  }

  MY->mkfile("$html_dir/foo.yatt", <<'END');
<!yatt:args "/{path:.*}">
<h2>Hello &yatt:path;</h2>

END

  {
    my Env $psgi = (GET my $path = "/foo.yatt/../../outside.yatt")->to_psgi;

    $tester->psgi_status($psgi, 403, $path);
  }
}

#========================================
chdir($CWD);

done_testing();
