#!/usr/bin/env perl
# -*- coding: utf-8 -*-
use strict;
use warnings qw(FATAL all NONFATAL misc);
use utf8;
#use encoding ':_get_locale_encoding';
#BEGIN { binmode STDERR, ":encoding(@{[_get_locale_encoding()]})"; }
BEGIN {
  binmode STDERR, ":encoding(utf8)";
  binmode STDOUT, ":encoding(utf8)";
}

use Test::More;
use Test::WWW::Mechanize::PSGI;

foreach my $mod (qw/Locale::PO/) {
  unless (eval "require $mod") {
    plan skip_all => "module $mod is not installed";
  }
}

use FindBin;
BEGIN {
  my $dir = "$FindBin::RealBin/../../../../t";
  $dir = $FindBin::RealBin unless -d $dir;
  local (@_, $@) = $dir;
  do "$dir/t_lib.pl";
  die $@ if $@;
}

use YATT::Lite::Factory;
use YATT::Lite::Util qw/lexpand/;

ok(my $SITE = YATT::Lite::Factory->find_load_factory_script
   (dir => dirname($FindBin::Bin))
   , "app.psgi is loaded");

$SITE->configure(debug_psgi => 0
		 , debug_backend => 0
		 , debug_connection => 0
		 , session_debug => 0
		 , logfile => undef
                 , site_prefix => ""
		);

my $dirapp = $SITE->get_yatt('/');
my @docpath = lexpand($dirapp->cget('docpath'));

{
  my $mech = Test::WWW::Mechanize::PSGI->new(app => $SITE->to_app);
  $mech->add_header('Accept-Language', 'ja');

  {
    $mech->get_ok("/");
    $mech->title_is('ylpodview');
    $mech->content_contains(my $prompt = 'モジュール');
    my $homelink = $mech->find_link(text => 'ylpodview');
    is $homelink->url, "/", "home link url";
  }

  SKIP: {
    skip "No index.lst", 7 unless -r "$docpath[0]/index.lst";

    ok(my $readme = $mech->find_link(text => 'readme'), "found readme link");
    is $readme->url, "/mod/YATT::Lite::docs::readme", "readme link url";
    $mech->get_ok($readme);
    #----------------------------------------

    ok(my $NAME = $mech->find_link(text => 'NAME'), "found NAME link");
    is $NAME->url, "#--NAME", "nav link for NAME";

    ok(my $psgi = $mech->find_link(text => 'PSGI'), "found PSGI link");
    is $psgi->url, "/mod/PSGI", "PSGI link url";

    #----------------------------------------
    $mech->back;
  }

  {
    ok(my $englink = $mech->find_link(text_regex => qr/English/)
       , "langswitch English");
  }

  {
    $mech->get("/test");
    $mech->title_is('Inline url pattern test:');
    $mech->get("/test/foobar");
    $mech->title_is('Inline url pattern test: foobar');
    $mech->get("/test/foo/bar");
    $mech->title_is('foo: bar');
    $mech->get("/test/bar/baz");
    $mech->title_is('bar: baz');
  }


}

done_testing();
