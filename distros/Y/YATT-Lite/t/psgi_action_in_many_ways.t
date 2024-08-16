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

  sub psgi_returns {
    my ($self, $psgi, $expect, $it_should) = @_;
    my $got;
    if (my $err = YATT::Lite::Util::catch {
      $got = $self->[0]->call($psgi);
    }) {
      Test::More::fail("$it_should: $err");
    } else {
      Test::More::is_deeply($got, $expect, $it_should);
    }
  }
}

my $TEMPDIR = tempdir(CLEANUP => 1);
my $CWD = cwd();
my $TESTNO = 0;
my $CT = ["Content-Type", q{text/html; charset="utf-8"}];

my $TEST_TODO = $ENV{TEST_TODO};

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

my $with_or_without = sub {$_[0] ? "With" : "Without"};

#========================================

foreach my $has_index (1, 0) {

  subtest $with_or_without->($has_index)." index.yatt", sub {

    subtest "foo.ydo", sub {
      my ($app_root, $html_dir, $site) = $make_siteapp->($make_dirs->());

      my $tester = t_call_tester->new($site);

      MY->mkfile("$html_dir/index.yatt", <<'END') if $has_index;
<h2>Hello</h2>

<!yatt:action "/foo">
# should not be called (hidden by foo.ydo)
print $CON "action foo in index.yatt";

<!yatt:action "/bar">
print $CON "action bar in index.yatt";
END

      MY->mkfile("$html_dir/foo.ydo", <<'END');
use strict;
return sub {
  my ($this, $CON) = @_;
  print $CON "action in foo.ydo";
};
END

      subtest "request /foo.ydo", sub {
        my Env $psgi = (GET "/foo.ydo")->to_psgi;

        $tester->psgi_returns($psgi, [200, $CT, ["action in foo.ydo"]]
                              , "it should invoke action in foo.ydo");
      };

      # TODO:
      if (1) {
        subtest "request /foo", sub {
          my Env $psgi = (GET "/foo")->to_psgi;

          $tester->psgi_returns($psgi, [200, $CT, ["action in foo.ydo"]]
                                , "it should invoke action in foo.ydo");
        };
      }

      if ($has_index) {
        subtest "request /bar (for sanity check)", sub {
          my Env $psgi = (GET "/bar")->to_psgi;

          $tester->psgi_returns($psgi, [200, $CT, ["action bar in index.yatt"]]
                                , "it should invoke action bar in index.yatt");
        };
      }
    };

    TODO:
    ($has_index or $TEST_TODO)
      and
    subtest "Action in .htyattrc.pl", sub {
      local $TODO = $TEST_TODO ? undef : "Not yet solved";
      my ($app_root, $html_dir) = $make_dirs->();

      make_path(my $tmpl_dir = "$app_root/ytmpl");

      MY->mkfile("$html_dir/index.yatt", <<'END') if $has_index;
<h2>Hello</h2>

<!yatt:page "/bar">
page bar in index.yatt
END

      # .htyattrc.pl should be created BEFORE siteapp->new.
      MY->mkfile("$html_dir/.htyattrc.pl", <<'END');
use strict;

use YATT::Lite qw/Action/;

Action foo => sub {
  my ($this, $CON) = @_;
  print $CON "action foo in .htyattrc.pl";
};

END

      my $site = $make_siteapp->($app_root, $html_dir, app_base => '@ytmpl');
      my $tester = t_call_tester->new($site);

      if ($has_index or $TEST_TODO) {
        subtest "request /?!foo=1", sub {
          my Env $psgi = (GET "/?!foo=1")->to_psgi;

          $tester->psgi_returns($psgi, [200, $CT, ["action foo in .htyattrc.pl"]]
                                , "it should invoke action foo in .htyattrc.pl");
        };
      }

      if ($TEST_TODO) {
        subtest "request /foo", sub {
          my Env $psgi = (GET "/foo")->to_psgi;

          $tester->psgi_returns($psgi, [200, $CT, ["action foo in .htyattrc.pl"]]
                                , "it should invoke action foo in .htyattrc.pl");
        };
      }
    };

    TODO:
    ($has_index)
      and
    subtest "site->mount_action(URL, subref)", sub {
      local $TODO = $TEST_TODO ? undef : "Not yet solved";
      my ($app_root, $html_dir) = $make_dirs->();

      make_path($html_dir);

      MY->mkfile("$html_dir/index.yatt", <<'END') if $has_index;
<h2>Hello</h2>

<!yatt:page "/bar">
page bar in index.yatt
END

      my $site = $make_siteapp->($app_root, $html_dir, app_base => '@ytmpl');
      my $tester = t_call_tester->new($site);

      $site->mount_action(
        '/foo',
        sub {
          my ($this, $con) = @_;
          print $con "action foo from mount_action";
        }
      );

      if ($TEST_TODO) {
        subtest "request /?!foo=1", sub {
          my Env $psgi = (GET "/?!foo=1")->to_psgi;

          $tester->psgi_returns($psgi, [200, $CT, ["action foo from mount_action"]]
                                , "it should invoke action foo from mount_action");
        };
      }

      subtest "request /foo", sub {
        my Env $psgi = (GET "/foo")->to_psgi;

        $tester->psgi_returns($psgi, [200, $CT, ["action foo from mount_action"]]
                              , "it should invoke action foo from mount_action");
      };
    };
  };
}

#========================================
chdir($CWD);

done_testing();
