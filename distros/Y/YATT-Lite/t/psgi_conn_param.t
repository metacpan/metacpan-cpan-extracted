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

my $site = YATT::Lite::WebMVC0::SiteApp
  ->new(  app_root => $FindBin::Bin
	  , doc_root => "$rootname.d"
	  # Below is required (currently) to decode input parameters.
	  , header_charset => 'utf-8'
	  , tmpl_encoding => 'utf-8'
	  , output_encoding => 'utf-8'
      );
my $app = $site->to_app;

my $client = Plack::Test->create($app);

sub test_action (&$;@) {
  _test_action(@_);
}

sub _test_action {
    my ( $subref, $request, %params ) = @_;

    $site->mount_action("/test", $subref);

    {
      local $@;
      my $res;
      eval {
	$res = $client->request($request, %params);
      };
      BAIL_OUT($@) if $@;
    }
}


#
# TESTS
#

test_action {
    my ( $this, $con ) = @_;
    isa_ok ( $con, "YATT::Lite::WebMVC0::Connection" );
} GET "/test?foo=bar";

test_action {
    my ( $this, $con ) = @_;
    is ( $con->param('foo'), 'bar', "param('foo')" );
} GET "/test?foo=bar";

test_action {
    my ( $this, $con ) = @_;
    is( $con->raw_body, 'yatt ansin! utyuryokou', "raw_body" );
} POST "/test", Content => 'yatt ansin! utyuryokou';

test_action {
    my ( $this, $con ) = @_;
    is( $con->param('foo'), 'bar', "param with query path" );
    is( $con->raw_body, 'yatt ansin! utyuryokou', "raw_body with query path" );
} POST "/test?foo=bar", Content => 'yatt ansin! utyuryokou';

#
# Tests for encoding
#

{
  use utf8;
  use Encode qw/is_utf8/;
  our $TEST_TYPE;
  my $t1 = sub {
    my ($this, $con) = @_;

    my $meth = $TEST_TYPE || $con->request_method;

    my ($kanji_name) = grep {/^kanji/} $con->param;
    is is_utf8($kanji_name), 1
      , "[$meth] KEY of qstr kanji.. is decoded";
    is $kanji_name, 'kanjiかんじ'
      , "[$meth] KEY is collect";

    my $value = $con->param($kanji_name);
    is is_utf8($value), 1
      , "[$meth] VAL of qstr kanji.. is decoded";
    is $value, '漢字'
      , "[$meth] VAL is collect";
  };

  _test_action
    ($t1, GET "/test?kanji%E3%81%8B%E3%82%93%E3%81%98=%E6%BC%A2%E5%AD%97");

  _test_action
    ($t1, POST "/test", Content => ['kanjiかんじ' => "漢字"]);

  test_action {
    my ($this, $con) = @_;

    local $TEST_TYPE = my $meth = "MIXED";
    $t1->($this, $con);

    my ($hiragana_name) = grep {/^hira/} $con->param;
    is is_utf8($hiragana_name), 1
      , "[$meth] KEY of qstr hira... is decoded";
    is $hiragana_name, 'hiragana_of平仮名'
      , "[$meth] KEY is collect";

    my $value = $con->param($hiragana_name);
    is is_utf8($value), 1
      , "[$meth] VAL of qstr hira... is decoded";
    is $value, 'ひらがな'
      , "[$meth] VAL is collect";

  } POST "/test?hiragana_of平仮名=ひらがな"
    , Content => ['kanjiかんじ' => "漢字"];

  my $breakpoint = 1; # just for breakpoint

  test_action {
    my ($this, $con) = @_;
    my $pi = $con->cget('env')->{PATH_INFO};
    is is_utf8($pi), 1, "PATH_INFO is decoded utf8";
    is $pi, "/test/hiragana_of平仮名", "PATH_INFO is valid";
  } GET "/test/hiragana_of平仮名";
}

done_testing();
