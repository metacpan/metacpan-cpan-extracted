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

BEGIN {
  foreach my $req (qw(Plack Plack::Test Plack::Response HTTP::Request::Common)) {
    unless (eval qq{require $req;}) {
      plan skip_all => "$req is not installed."; exit;
    }
    $req->import;
  }
}

my $rootname = untaint_any($FindBin::Bin."/psgi");

sub make_site {
  my (@opts) = @_;
  my $site = YATT::Lite::WebMVC0::SiteApp
    ->new(app_root => $FindBin::Bin
	  , doc_root => "$rootname.d"
	  # Below is required (currently) to decode input parameters.
	  , header_charset => 'utf-8'
	  , tmpl_encoding => 'utf-8'
	  , output_encoding => 'utf-8'
	  , @opts
	);
  ($site, Plack::Test->create($site->to_app));
}

my ($site_a, $client_a) = make_site(app_ns => 'MyYATTGH259A');
my ($site_b, $client_b) = make_site(app_ns => 'MyYATTGH259B'
				    , mkquery_with_body_params => 1);

sub run_action {
  my ($site, $client, $subref, $request) = @_;
  $site->mount_action("/test", $subref);
  local $@;
  eval {$client->request($request)};
  BAIL_OUT($@) if $@;
}

#========================================
# Site A (default): POST body params must not leak into reproduced urls.
#========================================

run_action($site_a, $client_a, sub {
  my ($this, $con) = @_;
  is $con->current_path($con), "/test?foo=bar&m=1&m=2"
    , "[default] current_path(CON) reproduces query params only (order kept)";
  is scalar($con->mkquery($con)), "?foo=bar&m=1&m=2"
    , "[default] mkquery(CON) reproduces query params only";
  is $con->param('nx'), 'secret'
    , "[default] body param is still accessible via param()";
}, POST "/test?foo=bar&m=1&m=2", Content => [nx => 'secret']);

run_action($site_a, $client_a, sub {
  my ($this, $con) = @_;
  is $con->current_path($con), "/test"
    , "[default] POST without query string => bare path";
}, POST "/test", Content => [nx => 'secret']);

run_action($site_a, $client_a, sub {
  my ($this, $con) = @_;
  is $con->current_path($con), "/test?foo=bar"
    , "[default] GET is unchanged";
}, GET "/test?foo=bar");

run_action($site_a, $client_a, sub {
  my ($this, $con) = @_;
  is $con->current_path($con), "/test?%E3%81%8B=%E3%81%AA"
    , "[default] utf8 query params are reproduced byte-faithfully";
}, POST "/test?%E3%81%8B=%E3%81%AA", Content => [nx => 'x']);

#========================================
# Site B (mkquery_with_body_params => 1): old merged behavior.
#========================================

run_action($site_b, $client_b, sub {
  my ($this, $con) = @_;
  is $con->current_path($con), "/test?foo=bar&nx=secret"
    , "[compat] current_path(CON) reproduces body params too (sorted)";
}, POST "/test?foo=bar", Content => [nx => 'secret']);

done_testing();
