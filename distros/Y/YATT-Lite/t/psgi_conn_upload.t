#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::More;
use YATT::t::t_preload; # To make Devel::Cover happy.
use YATT::Lite::WebMVC0::SiteApp;
use YATT::Lite::Util qw/read_file/;

use File::Basename;
use List::Util qw/sum/;

BEGIN {
  foreach my $req (qw(Plack Plack::Test Plack::Response HTTP::Request::Common)) {
    unless (eval qq{require $req;}) {
      plan skip_all => "$req is not installed."; exit;
    }
    $req->import;
  }
}

# Share doc_root with psgi.t
my $rootname = untaint_any($FindBin::Bin."/psgi");

my $site = YATT::Lite::WebMVC0::SiteApp
  ->new(  app_root => $FindBin::Bin
        , doc_root => "$rootname.d"
        , header_charset => 'utf-8'
       );

my $client = Plack::Test->create($site->to_app);

my @TESTS;

sub test_action (&$$;@) {
  my ($subref, $ntests, $request, %params ) = @_;

  push @TESTS, [$ntests, sub {
		  my $path = $request->uri->path;

		  $site->mount_action($path, $subref);

		  $client->request($request, %params);
		}];
}

#
# TESTS
#

test_action {
  my ($this, $con) = @_;
  is($con->param('q1'), "a1"
     , "param('q1') = a1");
  is((my $up = $con->upload('file1'))->filename, "uploaded.png"
     , "uploaded png");
  is(read_file($up->path), "foobar"
    , "uploaded content");
} 3, POST "/upload", [q1 => "a1"
		      , file1 => [undef, "uploaded.png", Content => "foobar"]]
  , "Content-Type" => "form-data";

test_action {
  my ($this, $con) = @_;
  is_deeply(scalar $con->param('x')
	    , +{"y" => {"z" => "1"}}
	    , "x[y][z]=1");
  is(read_file($con->upload('file2')->path), "baz"
    , "uploaded content");
} 2, POST "/upload", ["x[y][z]" => "1"
		      , file2 => [undef, "up2.png", Content => "baz"]]
  , "Content-Type" => "form-data";

plan tests => sum map {$$_[0]} @TESTS;

$$_[1]->() for @TESTS;

done_testing();
