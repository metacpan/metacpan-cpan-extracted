#!/usr/bin/env perl
# -*- coding: utf-8 -*-
use strict;
use warnings;

use mro 'c3';
use File::Spec;
use File::Basename ();
use Cwd ();
use Config '%Config';
{
  my ($app_root, @libdir);
  BEGIN {
    if (-r __FILE__) {
      # detect where app.psgi is placed.
      $app_root = File::Basename::dirname(File::Spec->rel2abs(__FILE__));
    } else {
      # older uwsgi do not set __FILE__ correctly, so use cwd instead.
      $app_root = Cwd::cwd();
    }
    if (-d (my $dn = "$app_root/lib")) {
      push @libdir, $dn
    } elsif (my ($found) = $app_root =~ m{^(.*?/)YATT/}) {
      push @libdir, $found;
    }
    if (-d (my $dn = "$app_root/extlib")) {
      push @libdir, $dn;
    }
  }
  use lib @libdir;

  # To have siteapp-wide entity, we extend it.
  use YATT::Lite::WebMVC0::SiteApp -as_base;
  use YATT::Lite qw/Entity *CON/;

  use YATT::Lite::WebMVC0::Partial::LangSwitch;

  use YATT::Lite::PSGIEnv;

  my @docpath;
  {
    while (@ARGV and -d $ARGV[0]) {
      push @docpath, shift @ARGV;
    }

    unless (@docpath) {
      push @docpath, grep {-d} map {"$app_root/$_"} qw|pod pods docs doc|;
      unless (@docpath) {
	push @docpath, map {
	  my $d = "$_/YATT/Lite/docs";
	  -d $d ? $d : ()
	} @libdir;
      }
      push @docpath, MY->rel2abs(".");
    }

    push @docpath, map {
      if (-d "$_/pod") {
	("$_/pod", $_)
      } else {
	$_
      }
    } grep {-d} @INC;

    push @docpath, grep(-d, split($Config{path_sep}, $ENV{'PATH'}));
  }

  my $dispatcher = MY->new
    (app_ns => 'MyApp'
     , app_root => $app_root
     , doc_root => "$app_root/html"
     , (-d "$app_root/ytmpl" ? (app_base => '@ytmpl') : ())
     , namespace => ['yatt', 'perl', 'js']
     , header_charset => 'utf-8'
     , tmpl_encoding => 'utf-8'
     , output_encoding => 'utf-8'
     , use_subpath => 1
     , (@docpath
	? (psgi_fallback => MY->psgi_file_app($docpath[0])) : ())
    );

  # Use given argument as docpath (or use current directory instead).
  {
    my $dirapp = $dispatcher->get_yatt('/');

    $dirapp->configure(docpath => [map {
      $dispatcher->rel2abs($_)
    } @docpath]);
  }

  my $app = $dispatcher->to_app;

  unless (caller) {
    require Plack::Runner;
    my $runner = Plack::Runner->new(app => $app);
    $runner->parse_options(@ARGV);
    $runner->run;
  } elsif ($dispatcher->want_object) {
    return $dispatcher;
  } else {
    return $app;
  }
}
