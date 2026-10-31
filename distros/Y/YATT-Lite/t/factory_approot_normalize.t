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

use File::Temp qw/tempdir/;
use YATT::Lite::Util::File qw/mkfile_may_wait/;
use File::Path qw(make_path);
use Cwd;

my $TEMPDIR = tempdir(CLEANUP => 1);
my $CWD = cwd();
my $TESTNO = 0;

#========================================
# GH-260: app_root ending with '..' (e.g. when the psgi is loaded as
# "$FindBin::Bin/../app.psgi" from a test) must be normalized lexically.
# Otherwise the sibling config dir "$app_root.config.d" becomes
# ".../t/...config.d" (three dots) and every config file is silently ignored.

my $make_app = sub {
  my $app_root = "$TEMPDIR/myapp" . ++$TESTNO;
  make_path("$app_root/t", "$app_root/html");
  MY->mkfile_may_wait("$app_root/app.psgi", "# dummy, only the path matters\n");
  MY->mkfile_may_wait("$app_root/html/index.yatt", "hello\n");
  ($app_root, "$app_root.config.d");
};

describe "YATT::Lite::Util::normalize_fs_path", sub {
  my @cases = (
    ["/a/t/.."      => "/a"],
    ["/a/t/../b"    => "/a/b"],
    ["/a/t.d/.."    => "/a"],
    ["/a/b/../../c" => "/c"],
    ["/.."          => "/"],
    ["/"            => "/"],
    ["/a/"          => "/a"],
    ["/a/./b"       => "/a/b"],
    ["../x"         => "../x"],
    ["/a/b/c"       => "/a/b/c"],
  );
  foreach my $case (@cases) {
    my ($in, $out) = @$case;
    it "should map '$in' to '$out'", sub {
      expect(YATT::Lite::Util::normalize_fs_path($in))->to_be($out);
    };
  }
};

describe "load_factory_for_psgi with '..'-containing psgi path", sub {
  my ($app_root, $config_d) = $make_app->();
  MY->mkfile_may_wait("$config_d/app.xhf", <<'END');
use_sibling_config_dir: 1
site_prefix: /prefixed
END
  MY->mkfile_may_wait("$config_d/site_config.xhf", <<'END');
bar: baz
END

  my $site = YATT::Lite::WebMVC0::SiteApp
    ->create_factory_class("TestFactory$TESTNO")
    ->load_factory_for_psgi("$app_root/t/../app.psgi");

  it "should normalize app_root", sub {
    expect($site->cget('app_root'))->to_be($app_root);
  };

  it "should derive doc_root from the normalized app_root", sub {
    expect($site->cget('doc_root'))->to_be("$app_root/html");
  };

  it "should read sibling app.xhf", sub {
    expect($site->cget('site_prefix'))->to_be("/prefixed");
  };

  it "should point config_dir at the sibling config dir", sub {
    expect($site->config_dir)->to_be($config_d);
  };

  it "should read site_config from the sibling config dir", sub {
    expect($site->site_config->{bar})->to_be("baz");
  };
};

describe "explicit app_root ending with '..'", sub {
  my ($app_root, $config_d) = $make_app->();
  MY->mkfile_may_wait("$config_d/site_config.xhf", <<'END');
bar: direct
END

  my $site = YATT::Lite::WebMVC0::SiteApp
    ->create_factory_class("TestFactory$TESTNO")
    ->new(app_root => "$app_root/t/.."
          , doc_root => "$app_root/html"
          , use_sibling_config_dir => 1);

  it "should normalize app_root in after_new", sub {
    expect($site->cget('app_root'))->to_be($app_root);
  };

  it "should point config_dir at the sibling config dir", sub {
    expect($site->config_dir)->to_be($config_d);
  };

  it "should read site_config from the sibling config dir", sub {
    expect($site->site_config->{bar})->to_be("direct");
  };
};

describe "control: psgi path without '..'", sub {
  my ($app_root, $config_d) = $make_app->();
  MY->mkfile_may_wait("$config_d/app.xhf", <<'END');
use_sibling_config_dir: 1
site_prefix: /ctrl
END

  my $site = YATT::Lite::WebMVC0::SiteApp
    ->create_factory_class("TestFactory$TESTNO")
    ->load_factory_for_psgi("$app_root/app.psgi");

  it "should keep app_root as-is", sub {
    expect($site->cget('app_root'))->to_be($app_root);
  };

  it "should read sibling app.xhf", sub {
    expect($site->cget('site_prefix'))->to_be("/ctrl");
  };

  it "should point config_dir at the sibling config dir", sub {
    expect($site->config_dir)->to_be($config_d);
  };
};

describe "fallback: app.xhf under app_root when no sibling config dir", sub {
  my ($app_root, $config_d) = $make_app->();
  MY->mkfile_may_wait("$app_root/app.xhf", <<'END');
site_prefix: /plain
END

  my $site = YATT::Lite::WebMVC0::SiteApp
    ->create_factory_class("TestFactory$TESTNO")
    ->load_factory_for_psgi("$app_root/app.psgi");

  it "should read app.xhf next to app.psgi", sub {
    expect($site->cget('site_prefix'))->to_be("/plain");
  };
};

#========================================
chdir($CWD);

done_testing();
