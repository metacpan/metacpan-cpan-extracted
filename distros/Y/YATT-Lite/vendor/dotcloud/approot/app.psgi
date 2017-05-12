#!/usr/bin/perl
# -*- perl -*-
use strict;
use warnings qw(FATAL all NONFATAL misc);

use File::Spec;
use File::Basename ();
my $app_root;
use lib ($app_root = File::Basename::dirname(File::Spec->rel2abs(__FILE__)))
  . "/lib";

use YATT::Lite::WebMVC0::SiteApp;

my $dispatcher = YATT::Lite::WebMVC0::SiteApp->new
  (app_ns => 'MyApp'
   , app_root => $app_root
   , doc_root => "$app_root/html"
   , (-d "$app_root/ytmpl" ? (app_base => '@ytmpl') : ())
   , namespace => ['yatt', 'perl', 'js']
   , header_charset => 'utf-8'
   , debug_cgen => $ENV{DEBUG}
   , debug_cgi  => $ENV{DEBUG_CGI}
   # , is_gateway => $ENV{GATEWAY_INTERFACE} # Too early for FastCGI.
   # , tmpl_encoding => 'utf-8'
  );

if (caller && YATT::Lite::Factory->loading) {
  return $dispatcher;
}

unless (caller) {
  require Plack::Runner;
  my $runner = Plack::Runner->new;
  $runner->parse_options(@ARGV);
  return $runner->run($dispatcher->to_app);
}

$dispatcher->to_app;
