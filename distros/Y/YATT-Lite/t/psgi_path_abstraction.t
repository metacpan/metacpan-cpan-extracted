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

foreach my $test (combination(['', '/foo/bar']
                              , [[path_translated => 1], [direct => 0]]))
{
  my ($script_name, $mode) = @$test;
  my ($theme, $use_path_translated) = @$mode;

  my $make_test_env = sub {
    my $app_root = "$tempdir/t" . ++$testno . $script_name;
    my $real_dir = "$app_root/html";
    make_path($real_dir);

    my $mkpsgi = sub {
      my ($url) = @_;
      my $URI = URI->new($url);
      my Env $env = (GET $url)->to_psgi;

      if ($use_path_translated) {
        # Test for Apache config like:
        #
        #   Action x-psgi-handler $script_name/cgi-bin/dispatch.cgi
        #   AddHandler x-psgi-handler .yatt .ytmpl .ydo
        #
        #
        # With above config, SCRIPT_NAME contains /cgi-bin/dispatch.cgi part.
        # This harms use of SCRIPT_NAME for path abstraction.
        # So, &yatt:script_name(); tries to trim it.
        #
        $env->{SCRIPT_NAME} = "$script_name/cgi-bin/dispatch.cgi";
        $env->{SCRIPT_FILENAME} = "$real_dir/cgi-bin/dispatch.cgi";

        # Below mimics DirectoryIndex behavior.
        #
        my $path = $URI->path;

        $path =~ s,/$,/index,;

        $env->{PATH_TRANSLATED} = "$real_dir$path.yatt";

        # Other cgi fields set by Apache.
        #
        $env->{REDIRECT_HANDLER} = 'x-psgi-handler';
        $env->{REDIRECT_STATUS} = 200;
        $env->{REDIRECT_URL} = "$path.yatt";

      } else {
        #
        # Normal case.
        #
        $env->{SCRIPT_NAME} = $script_name;
      }
      $env;
    };

    my $site = YATT::Lite::WebMVC0::SiteApp
      ->new(app_ns => "Test$testno"
            , app_root => $app_root
            , doc_root => $real_dir);

    ($real_dir, $site, $mkpsgi);
  };

  describe "When expected script_name is ($script_name) with $theme mode,", sub {

    {
      my ($real_dir, $site, $mkpsgi) = $make_test_env->();

      my $item = 0;
      $item++;
      foreach my $req (
        ['/' => 'index'],
        ["/test$item", "test$item"],
        ['/zzz/?test=foo' => 'zzz/index'],
      ) {
        my ($url, $wname) = @$req;

        {
          MY->mkfile("$real_dir/$wname.yatt"
                     , qq{<!yatt:args test>\n(&yatt:script_name();)});

          my Env $psgi = $mkpsgi->($url);

          describe "&yatt:script_name(); for (SCRIPT_NAME=$psgi->{SCRIPT_NAME}) in (url=$url file=$script_name/$wname.yatt)", sub {

            it "should return ($script_name)", sub {

              expect($site->call($psgi))->to_be([200, $CT, ["($script_name)"]]);
            };
          };
        }
      }
    }

    {
      my ($real_dir, $site, $mkpsgi) = $make_test_env->();

      my $item = 0;
      $item++;
      foreach my $req (
        ['/' => 'index'],
        ["/test$item", "test$item"],
        ['/zzz/?test=foo' => 'zzz/index'],
      ) {
        my ($url, $wname) = @$req;
        my $path = URI->new($url)->path;

        {
          MY->mkfile("$real_dir/$wname.yatt"
                     , qq{<!yatt:args test>\n(&yatt:file_location();)});

          my Env $psgi = $mkpsgi->($url);

          describe "&yatt:file_location(); for (SCRIPT_NAME=$psgi->{SCRIPT_NAME}) in (url=$url file=$script_name/$wname.yatt)", sub {

            it "should return ($script_name$path)", sub {

              expect($site->call($psgi))->to_be([200, $CT, ["($script_name$path)"]]);
            };
          };
        }
      }
    }
  };
}

{
  my $theme = 'x_forwarded_proto';
  my $app_root = "$tempdir/t" . ++$testno . $theme;
  my $real_dir = "$app_root/html";
  make_path($real_dir);

  my $site = YATT::Lite::WebMVC0::SiteApp
    ->new(app_ns => "Test$testno"
          , app_root => $app_root
          , doc_root => $real_dir);

  my $exampleUrl = "//example.com";
  my @tests = (['/', 'index.yatt'], ['/test', 'test.yatt']);

  describe "&yatt:script_uri();", sub {

    describe "normally", sub {

      foreach my $test (@tests) {
        my ($loc, $file) = @$test;
        my $urlMain = $exampleUrl.$loc;
        MY->mkfile("$real_dir/$file"
                   , qq{<!yatt:args test>\n(&yatt:script_uri();)});
        my $psgi = (GET "http:$urlMain")->to_psgi;

        it "should return http:$urlMain for $file", sub {

          expect($site->call($psgi))->to_be([200, $CT, ["(http:$urlMain)"]]);
        };
      }
    };

    describe "when HTTP_X_FORWARDED_PROTO=https", sub {
      foreach my $test (@tests) {
        my ($loc, $file) = @$test;
        my $urlMain = $exampleUrl.$loc;
        my $psgi = (GET "http:$urlMain")->to_psgi;
        $psgi->{HTTP_X_FORWARDED_PROTO} = 'https';

        it "should return https:$urlMain", sub {
          expect($site->call($psgi))->to_be([200, $CT, ["(https:$urlMain)"]]);
        };
      }
    };
  };

}

chdir($cwd);

done_testing();
