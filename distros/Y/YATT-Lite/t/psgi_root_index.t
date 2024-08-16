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

my $tempdir = tempdir(CLEANUP => 1);
my $testno = 0;
my $CT = ["Content-Type", q{text/html; charset="utf-8"}];

my $cwd = cwd();

foreach my $test (['' => [path_translated => 1]]
                    , ['' => [direct => 0]])
{
  my ($script_name, $mode) = @$test;
  my ($theme, $use_path_translated) = @$mode;

  my $make_test_env = sub {
    my $app_root = "$tempdir/t" . ++$testno . $script_name;
    my $real_dir = "$app_root/html";
    make_path($real_dir);

    my $site = YATT::Lite::WebMVC0::SiteApp
      ->new(app_ns => "Test$testno"
            , app_root => $app_root
            , doc_root => $real_dir
            , ext_public => 'html'
          );

    ($app_root, $real_dir, $site);
  };

  describe "index.html in $theme mode,", sub {

    {
      my ($app_root, $real_dir, $site) = $make_test_env->();

      MY->mkfile("$real_dir/index.html"
                   , qq{<h2>Hello world!</h2>});

      my ($url, $file) = ("/", "/index.html");
      my Env $psgi = do {

        my Env $env = (GET $url)->to_psgi;

        # Test for Apache config like:
        #
        #   Action x-psgi-handler $script_name/cgi-bin/dispatch.fcgi
        #   AddHandler x-psgi-handler .html .ytmpl .ydo
        #
        #
        # With above config, SCRIPT_NAME contains /cgi-bin/dispatch.cgi part.
        # This harms use of SCRIPT_NAME for path abstraction.
        # So, &yatt:script_name(); tries to trim it.
        #
        $env->{SCRIPT_NAME} = "$script_name/cgi-bin/dispatch.fcgi";
        $env->{SCRIPT_FILENAME} = "$app_root/cgi-bin/dispatch.fcgi";

        # Below mimics DirectoryIndex behavior.
        #
        $env->{PATH_TRANSLATED} = "$real_dir$file";
        $env->{PATH_INFO} = $file;

        # Other cgi fields set by Apache.
        #
        $env->{REDIRECT_HANDLER} = 'x-psgi-handler';
        $env->{REDIRECT_STATUS} = 200;
        $env->{REDIRECT_URL} = $file;

        $env;
      };

      expect($site->call($psgi))->to_be([200, $CT, [q(<h2>Hello world!</h2>)]]);
    };

  };
}

chdir($cwd);

done_testing();
