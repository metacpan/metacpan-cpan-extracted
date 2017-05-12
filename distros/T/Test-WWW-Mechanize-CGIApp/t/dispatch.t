#!perl

use strict;
use warnings;
use Test::More;

use lib 'lib';
use lib 't/lib';

eval "use CGI::Application::Dispatch";
plan skip_all => "Won't test dispatch if CGI::Application::Dispatch isn't installed." if $@;

plan tests => 13;

use Test::WWW::Mechanize::CGIApp;

my $mech = Test::WWW::Mechanize::CGIApp->new();

$mech->app('MyDispatch');

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
