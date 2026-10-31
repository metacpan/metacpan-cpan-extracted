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
use YATT::Lite::Util::File qw/mkfile_may_wait/;
use File::Path qw(make_path);
use Cwd;

use YATT::Lite::PSGIEnv;

my $tempdir = tempdir(CLEANUP => 1);
my $testno = 0;
my $CT = ["Content-Type", q{text/html; charset="utf-8"}];

my $cwd = cwd();

foreach my $test (
  combination(['', '/foo/bar']
              , [[path_translated => 1], [direct => 0]]),
  ['/foo/', ['direct, trailing/', 0], '/foo'],
)
{
  my ($script_name, $mode, $expected_script_name) = @$test;
  $expected_script_name //= $script_name;
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

  describe "When expected script_name is ($expected_script_name) with $theme mode,", sub {

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
          MY->mkfile_may_wait("$real_dir/$wname.yatt"
                     , qq{<!yatt:args test>\n(&yatt:script_name();)});

          my Env $psgi = $mkpsgi->($url);

          describe "&yatt:script_name(); for (SCRIPT_NAME=$psgi->{SCRIPT_NAME}) in (url=$url file=$script_name/$wname.yatt)", sub {

            it "should return ($expected_script_name)", sub {

              expect($site->call($psgi))->to_be([200, $CT, ["($expected_script_name)"]]);
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
          MY->mkfile_may_wait("$real_dir/$wname.yatt"
                     , qq{<!yatt:args test>\n(&yatt:file_location();)});

          my Env $psgi = $mkpsgi->($url);

          describe "&yatt:file_location(); for (SCRIPT_NAME=$psgi->{SCRIPT_NAME}) in (url=$url file=$script_name/$wname.yatt)", sub {

            it "should return ($expected_script_name$path)", sub {

              expect($site->call($psgi))->to_be([200, $CT, ["($expected_script_name$path)"]]);
            };
          };
        }
      }
    }

    # GH-251: site_path/current_path entities.
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
          MY->mkfile_may_wait("$real_dir/$wname.yatt"
                     , qq{<!yatt:args test>\n}
                     . qq{(&yatt:site_path();)}
                     . qq{(&yatt:site_path(/admin/,[page,2]);)}
                     . qq{(&yatt:current_path();)});

          my Env $psgi = $mkpsgi->($url);

          describe "&yatt:site_path(); family for (SCRIPT_NAME=$psgi->{SCRIPT_NAME}) in (url=$url file=$script_name/$wname.yatt)", sub {

            it "should return prefix-aware paths", sub {

              expect($site->call($psgi))->to_be
                ([200, $CT, ["($expected_script_name/)"
                             . "($expected_script_name/admin/?page=2)"
                             . "($path)"]]);
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
        MY->mkfile_may_wait("$real_dir/$file"
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

{
  # GH-251: mkurl(,,mapped_path,1,local,1) should keep mount prefix.
  my $theme = 'gh251_mapped_path';
  my $app_root = "$tempdir/t" . ++$testno . $theme;
  my $real_dir = "$app_root/html";
  make_path($real_dir);

  my $site = YATT::Lite::WebMVC0::SiteApp
    ->new(app_ns => "Test$testno"
          , app_root => $app_root
          , doc_root => $real_dir);

  MY->mkfile_may_wait("$real_dir/item.yatt"
             , qq{<!yatt:args>\ntop\n}
             . qq{<!yatt:page detail="/detail/:id">\n}
             . qq{(&yatt:CON:mkurl(,,mapped_path,1,local,1);)}
             . qq{(&yatt:file_location();)}
             . qq{(&yatt:page_location();)});

  MY->mkfile_may_wait("$real_dir/zzz/index.yatt"
             , qq{<!yatt:args>\ntop\n}
             . qq{<!yatt:page detail="/detail/:id">\n}
             . qq{(&yatt:CON:mkurl(,,mapped_path,1,local,1);)}
             . qq{(&yatt:file_location();)}
             . qq{(&yatt:page_location();)});

  describe "mkurl(undef, undef, mapped_path => 1, local => 1)", sub {

    foreach my $mount ([root_mount => ''], [subpath_mount => '/myapp']) {
      my ($label, $script_name) = @$mount;

      # GH-251: mapped_path reproduces the requested url path and
      # file_location the page part of it, including how the request
      # spelled the file name (with/without ext, explicit index).
      foreach my $case (
        # [request path, file_location part, page_location part]
        ['/item/detail/3'      => '/item',      '/item'],
        ['/item.yatt/detail/3' => '/item.yatt', '/item'],
        ['/zzz/detail/4'       => '/zzz/',      '/zzz/'],
        ['/zzz/index/detail/4' => '/zzz/index', '/zzz/index'],
      ) {
        my ($path, $floc, $ploc) = @$case;

        it "should return ($script_name$path)($script_name$floc)($script_name$ploc) for ($label url=$path)", sub {
          my Env $psgi = (GET "http://example.com$path")->to_psgi;
          $psgi->{SCRIPT_NAME} = $script_name;
          $psgi->{PATH_INFO}   = $path;
          $psgi->{REQUEST_URI} = "$script_name$path";

          expect($site->call($psgi))->to_be
            ([200, $CT
              , ["($script_name$path)($script_name$floc)($script_name$ploc)"]]);
        };
      }
    }
  };

  describe "mkurl(mapped_path) under PATH_TRANSLATED mode", sub {

    # GH-251: PATH_TRANSLATED may be ext-completed by Apache
    # (MultiViews) even when the request omitted the ext, so
    # request_file must be corrected using REQUEST_URI.
    foreach my $case (
      # [request path, PATH_TRANSLATED, file_location, page_location]
      ['/item/detail/3',      "$real_dir/item/detail/3"
       , '/item',      '/item'],
      ['/item.yatt/detail/3', "$real_dir/item.yatt/detail/3"
       , '/item.yatt', '/item'],
      ['/item/detail/3',      "$real_dir/item.yatt/detail/3"
       , '/item',      '/item'],
    ) {
      my ($path, $pt, $floc, $ploc) = @$case;

      it "should return (/myapp$path)(/myapp$floc)(/myapp$ploc) for (url=$path PT=...$pt)", sub {
        my Env $psgi = (GET "http://example.com$path")->to_psgi;
        $psgi->{SCRIPT_NAME}     = "/myapp/cgi-bin/dispatch.cgi";
        $psgi->{SCRIPT_FILENAME} = "$real_dir/cgi-bin/dispatch.cgi";
        $psgi->{REDIRECT_HANDLER} = 'x-psgi-handler';
        $psgi->{REDIRECT_STATUS} = 200;
        $psgi->{PATH_TRANSLATED} = $pt;
        $psgi->{PATH_INFO}       = $path;
        $psgi->{REQUEST_URI}     = "/myapp$path";

        expect($site->call($psgi))->to_be
          ([200, $CT, ["(/myapp$path)(/myapp$floc)(/myapp$ploc)"]]);
      };
    }
  };
}

chdir($cwd);

done_testing();
