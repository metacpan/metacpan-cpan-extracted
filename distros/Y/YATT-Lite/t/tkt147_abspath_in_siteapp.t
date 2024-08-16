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
use YATT::Lite::Util::File qw/mkfile/;
use File::Path qw(make_path);
use Cwd;

use YATT::Lite::PSGIEnv;

my $tempdir = tempdir(CLEANUP => 1);
my $testno = 0;
my $CT = ["Content-Type", q{text/html; charset="utf-8"}];

my $cwd = cwd();

describe ":abspath() in path_translated_mode", sub {

  my $phys_prefix = "$tempdir/t" . ++$testno;
  my $phys_site_path = "$phys_prefix/test/apps/hkoba/foobar/test1";
  my $virt_site_prefix = "/test/hkoba/foobar/test1/-";

  my $app_root = $phys_site_path;
  my $real_dir = "$app_root/public";
  make_path($real_dir);

  my $site = YATT::Lite::WebMVC0::SiteApp
    ->new(app_ns => "Test$testno"
          , app_root => $app_root
          , doc_root => $real_dir);

  my $boot_script = "/cgi-bin/runplack.cgi";

  foreach my $test (
    ["/" => "/index.yatt"],
    ["/test1" => "/test1.yatt"],
  ) {
    my ($location, $file) = @$test;

    MY->mkfile("$real_dir$file", <<'END');
(&yatt:absrequest();)(&yatt:abspath();)
END

    my Env $env = (GET "$virt_site_prefix$location")->to_psgi;

    $env->{PATH_TRANSLATED} = "$phys_site_path/public$file";
    $env->{REDIRECT_HANDLER} = 'x-psgi-handler';
    $env->{REDIRECT_STATUS} = 200;
    $env->{REDIRECT_URL} = "$virt_site_prefix$file";

    $env->{REQUEST_URI} = "$virt_site_prefix$location";
    $env->{SCRIPT_FILENAME} = "$phys_site_path$boot_script";
    $env->{SCRIPT_NAME} = "$virt_site_prefix$boot_script";

    describe "when page $env->{REQUEST_URI} is requested, :abspath()", sub {
      it "should match to abspath in siteapp($location)", sub {
        expect($site->call($env))->to_be([200, $CT, ["($location)($file)\n"]]);
      };
    };

    describe "when request has trailing query_string, :absrequest()", sub {
      it "should work as expected still", sub {
        $env->{REQUEST_URI} .= "?foo=bar&xxx=yyy";
        expect($site->call($env))->to_be([200, $CT, ["($location)($file)\n"]]);
      };
    };
  }
};

chdir($cwd);

done_testing();
