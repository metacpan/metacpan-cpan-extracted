#!perl

use strict;
use warnings;

use lib 'lib';
use lib 't/lib';

use Test::More tests => 26;

use Test::WWW::Mechanize::CGIApp;

my $mech = Test::WWW::Mechanize::CGIApp->new();

SKIP: {
  eval "use CGI::Application::Dispatch";
  skip ("Don't test CA::Dispatch features if it isn't installed.", 13)
    unless (!$@);

  $mech->app(sub {
		    eval "require MyDispatch";
		    MyDispatch->dispatch;
		  });

  $mech->get_ok('/TestApp');
  is($mech->ct, "text/html");
  $mech->title_is("Welcome");
  $mech->content_contains("Home is where");

  $mech->get_ok('/TestApp/hello/');
  is($mech->ct, "text/html");
  $mech->title_is("Hello");
  $mech->content_contains("Hello world");

  $mech->follow_link_ok({ text => 'Whoopee_dispatch'});
  is($mech->ct, "text/html");
  $mech->title_is("Whoopee");
  $mech->content_contains("Whoopee");

  $mech = Test::WWW::Mechanize::CGIApp->new(app => 'MyDispatch');
  $mech->get_ok('/TestApp');
}

$mech->app(sub {
		  eval "require TestApp";
		  my $app = TestApp->new();
		  $app->run;
		});

$mech->get_ok('/');
is($mech->ct, "text/html");
$mech->title_is("Welcome");
$mech->content_contains("Home is where");

$mech->get_ok('/?rm=hello');
is($mech->ct, "text/html");
$mech->title_is("Hello");
$mech->content_contains("Hello world");

$mech->follow_link_ok({ text => 'Whoopee'});
is($mech->ct, "text/html");
$mech->title_is("Whoopee");
$mech->content_contains("Whoopee");

$mech = Test::WWW::Mechanize::CGIApp->new(app => 'TestApp');
$mech->get_ok('/TestApp');
