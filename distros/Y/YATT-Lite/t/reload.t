#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::Kantan;
use File::Temp qw/tempdir/;

use YATT::t::t_preload; # To make Devel::Cover happy.
use YATT::Lite::WebMVC0::SiteApp;
use YATT::Lite::Util::File qw/mkfile/;

my $tempdir = tempdir(CLEANUP => 1);
my $testno = 0;

describe "mode: reload requested only", sub {

  my $dir = "$tempdir/t" . ++$testno;

  MY->mkfile("$dir/html/index.yatt", qq{<yatt:foo/><yatt:bar/>});
  MY->mkfile("$dir/html/foo.ytmpl", qq{<h2>foo</h2>});
  MY->mkfile("$dir/html/bar.yatt", qq{<h2>bar</h2>});

  my $site = YATT::Lite::WebMVC0::SiteApp
    ->new(app_ns => "Test$testno", app_root => $dir, doc_root => "$dir/html");

  my $yatt_vfs = $site->get_yatt('/')->get_vfs;

  describe "Initially, index.yatt", sub {
    it "should be rendered", sub {
      expect($site->render("index"))->to_be("<h2>foo</h2><h2>bar</h2>");
    };

    describe "compilation counter of internal vfs", sub {
      my $ncomps;
      it "should be equal to 3 (index, foo, bar)", sub {
	expect($ncomps = $yatt_vfs->{n_compiles})->to_be(3);
      };

      it "should be unchanged after repeative access", sub {
	$site->render("index") for 0..9;

	expect($yatt_vfs->{n_compiles})->to_be($ncomps);
      };
    };

  };

  describe "When index.yatt is updated, index.yatt", sub {
    if (my ($slept) = MY->mkfile("$dir/html/index.yatt", qq{<yatt:foo/>})) {
      diag("slept $slept to update mtime of $dir/html/index.yatt");
    }

    it "should be rendered with new content immediately", sub {
      expect($site->render("index"))->to_be("<h2>foo</h2>");
    };

    describe "Compilation counter of internal vfs", sub {
      it "should be equal to 4 now.", sub {
	expect($yatt_vfs->{n_compiles})->to_be(4);
      };
    };
  };

  describe "When foo.ytmpl is updated, index.yatt", sub {
    if (my ($slept) = MY->mkfile("$dir/html/foo.ytmpl", qq{<h2>FOO</h2>})) {
      diag("slept $slept to update mtime of $dir/html/foo.ytmpl");
    }

    it "should be rendered with OLD content", sub {
      expect($site->render("index"))->to_be("<h2>foo</h2>");
    };

    describe "Compilation counter of internal vfs", sub {
      it "should be equal to 4 still.", sub {
	expect($yatt_vfs->{n_compiles})->to_be(4);
      };
    };
  };
};

describe "mode: always_refresh_deps", sub {

  my $dir = "$tempdir/t" . ++$testno;

  MY->mkfile("$dir/html/index.yatt", qq{<yatt:foo/><yatt:bar/>});
  MY->mkfile("$dir/html/foo.ytmpl", qq{<h2>foo</h2>});
  MY->mkfile("$dir/html/bar.yatt", qq{<h2>bar</h2>});

  my $site = YATT::Lite::WebMVC0::SiteApp
    ->new(app_ns => "Test$testno", app_root => $dir, doc_root => "$dir/html"
	  , always_refresh_deps => 1
	);

  my $yatt_vfs = $site->get_yatt('/')->get_vfs;

  describe "Initially, index.yatt", sub {
    it "should be rendered", sub {
      expect($site->render("index"))->to_be("<h2>foo</h2><h2>bar</h2>");
    };

    describe "compilation counter of internal vfs", sub {
      my $ncomps;
      it "should be equal to 3 (index, foo, bar)", sub {
	expect($ncomps = $yatt_vfs->{n_compiles})->to_be(3);
      };

      it "should be unchanged after repeative access", sub {
	$site->render("index") for 0..9;

	expect($yatt_vfs->{n_compiles})->to_be($ncomps);
      };
    };

  };

  describe "When foo.ytmpl is updated, index.yatt", sub {
    if (my ($slept) = MY->mkfile("$dir/html/foo.ytmpl", qq{<h2>FOO</h2>})) {
      diag("slept $slept to update mtime of $dir/html/foo.ytmpl");
    }

    it "should be rendered with NEW content in this time", sub {
      expect($site->render("index"))->to_be("<h2>FOO</h2><h2>bar</h2>");
    };

    describe "Compilation counter of internal vfs", sub {
      it "should be equal to 4 now.", sub {
	expect($yatt_vfs->{n_compiles})->to_be(4);
      };
    };
  };

  describe "When bar.yatt is updated, index.yatt", sub {
    if (my ($slept) = MY->mkfile("$dir/html/bar.yatt", qq{<h2>BAR</h2>})) {
      diag("slept $slept to update mtime of $dir/html/foo.ytmpl");
    }

    it "should be rendered with NEW content in this time", sub {
      expect($site->render("index"))->to_be("<h2>FOO</h2><h2>BAR</h2>");
    };

    describe "Compilation counter of internal vfs", sub {
      it "should be equal to 5 now.", sub {
	expect($yatt_vfs->{n_compiles})->to_be(5);
      };
    };
  };

  describe "When index.yatt is updated, index.yatt", sub {
    if (my ($slept) = MY->mkfile("$dir/html/index.yatt", qq{<yatt:foo/>})) {
      diag("slept $slept to update mtime of $dir/html/index.yatt");
    }

    it "should be rendered with new content immediately", sub {
      expect($site->render("index"))->to_be("<h2>FOO</h2>");
    };

    describe "Compilation counter of internal vfs", sub {
      my $ncomps = 6;
      it "should be equal to 6 now.", sub {
	expect($yatt_vfs->{n_compiles})->to_be($ncomps);
      };

      it "should be unchanged after repeative access", sub {
	$site->render("index") for 0..9;

	expect($yatt_vfs->{n_compiles})->to_be($ncomps);
      };
    };
  };

};



done_testing();
