#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::More;

use YATT::Lite::Breakpoint;

BEGIN {
  use_ok('YATT::Lite::Util',
	 qw(
	     terse_dump
	     parse_nested_query
	     ixhash
	  ));
  use_ok('Hash::MultiValue');
}

sub nil () {undef}

# Ported from:
# https://github.com/rack/rack/blob/master/test/spec_utils.rb

{
  my $THEME = "nested_query";

  my $qs2hmv = sub {
    # Stolen from Plack::Request#_parse_query
    [Hash::MultiValue->new
     (map { defined $_ ? do {s/\+/ /g; URI::Escape::uri_unescape($_) } : $_ }
      map { /=/ ? split(/=/, $_, 2) : ($_ => undef)}
      split(/[&;]/, $_[0]))->flatten];
  };

  my $ok = sub {
    my ($qs, $data) = @_;
    my $title = "[$THEME] " . ($qs . " --> ". terse_dump($data));
    is_deeply parse_nested_query($qs), $data, $title;
    is_deeply parse_nested_query($qs2hmv->($qs)), $data, "HMV: $title";
  };

  $ok->("foo=" => +{"foo" => ""});
  $ok->("foo=bar" => +{"foo" => "bar"});
  $ok->("foo=\"bar\"" => +{"foo" => "\"bar\""});

  $ok->("foo=bar&foo=quux" => +{"foo" => "quux"});
  $ok->("foo&foo=" => +{"foo" => ""});
  $ok->("foo=1&bar=2" => +{"foo" => "1", "bar" => "2"});
  $ok->("&foo=1&&bar=2" => +{"foo" => "1", "bar" => "2"});
  $ok->("foo&bar=" => +{"foo" => nil, "bar" => ""});
  $ok->("foo=bar&baz=" => +{"foo" => "bar", "baz" => ""});
  $ok->("my+weird+field=q1%212%22%27w%245%267%2Fz8%29%3F" => +{"my weird field" => q"q1!2\"'w$5&7/z8)?"});

  $ok->("a=b&pid%3D1234=1023" => +{"pid=1234" => "1023", "a" => "b"});

  $ok->("foo[]" => +{"foo" => [nil]});
  $ok->("foo[]=" => +{"foo" => [""]});
  $ok->("foo[]=bar" => +{"foo" => ["bar"]});

  $ok->("foo[]=1&foo[]=2" => +{"foo" => ["1", "2"]});
  $ok->("foo=bar&baz[]=1&baz[]=2&baz[]=3" => +{"foo" => "bar", "baz" => ["1", "2", "3"]});
  $ok->("foo[]=bar&baz[]=1&baz[]=2&baz[]=3" => +{"foo" => ["bar"], "baz" => ["1", "2", "3"]});

  $ok->("x[y][z]=1" => +{"x" => {"y" => {"z" => "1"}}});
  $ok->("x[y][z][]=1" => +{"x" => {"y" => {"z" => ["1"]}}});
  $ok->("x[y][z]=1&x[y][z]=2" => +{"x" => {"y" => {"z" => "2"}}});
  $ok->("x[y][z][]=1&x[y][z][]=2" => +{"x" => {"y" => {"z" => ["1", "2"]}}});

  $ok->("x[y][][z]=1" => +{"x" => {"y" => [{"z" => "1"}]}});
  $ok->("x[y][][z][]=1" => +{"x" => {"y" => [{"z" => ["1"]}]}});
  $ok->("x[y][][z]=1&x[y][][w]=2" => +{"x" => {"y" => [{"z" => "1", "w" => "2"}]}});

  $ok->("x[y][][v][w]=1" => +{"x" => {"y" => [{"v" => {"w" => "1"}}]}});
  $ok->("x[y][][z]=1&x[y][][v][w]=2" => +{"x" => {"y" => [{"z" => "1", "v" => {"w" => "2"}}]}});

  $ok->("x[y][][z]=1&x[y][][z]=2" => +{"x" => {"y" => [{"z" => "1"}, {"z" => "2"}]}});
  $ok->("x[y][][z]=1&x[y][][w]=a&x[y][][z]=2&x[y][][w]=3" => +{"x" => {"y" => [{"z" => "1", "w" => "a"}, {"z" => "2", "w" => "3"}]}});

  my $ng = sub {
    my ($qs, $err, $topic) = @_;
    my $title = "[$THEME] raises: " . ($topic || $err);
    local $@;
    eval {parse_nested_query($qs)};
    like $@, qr/^\Q$err\E/, $title;
  };

  $ng->("x[y]=1&x[y]z=2", "expected HASH (got String) for param `y'");

  $ng->("x[y]=1&x[]=1", "expected ARRAY (got HASH) for param `x'");

  $ng->("x[y]=1&x[y][][w]=2", "expected ARRAY (got String) for param `y'");
}

{
  my $BQ = sub {YATT::Lite::Util->build_nested_query(@_)};
  my $IS = sub {
    my ($object, $escaped) = @_;
    is_deeply($BQ->($object), $escaped
		, terse_dump($object)." --> ".terse_dump($escaped));
  };
  $IS->({foo => nil}, 'foo');
  $IS->({foo => ""}, 'foo=');
  $IS->({foo => "bar"}, 'foo=bar');

  is_deeply([split '&', $BQ->(ixhash("foo" => "1", "bar" => "2"))]
	      , [split '&', "foo=1&bar=2"]);

  # is_deeply([split '&', $BQ->(ixhash("foo" => "1", "bar" => 2))]
  # 	      , [split '&', "foo=1&bar=2"]);

  is_deeply([split '&', $BQ->(ixhash("my weird field" =>
						q;q1!2"'w$5&7/z8)?;
					     ))]
  	      , [split '&', "my+weird+field=q1%212%22%27w%245%267%2Fz8%29%3F"]);


  $IS->(ixhash("foo" => [nil]), "foo[]");
  $IS->(ixhash("foo" => [""]), "foo[]=");
  $IS->(ixhash("foo" => ["bar"]), "foo[]=bar");
  $IS->(ixhash("foo" => []), "");
  $IS->(ixhash("foo" => +{}), "");
  $IS->(ixhash('foo' => 'bar', 'baz' => []), 'foo=bar');
  $IS->(ixhash('foo' => 'bar', 'baz' => +{}), 'foo=bar');

  $IS->(ixhash('foo' => nil, 'bar' => ''), 'foo&bar=');
  $IS->(ixhash('foo' => 'bar', 'baz' => ''), 'foo=bar&baz=');
  $IS->(ixhash('foo' => 'bar', 'baz' => ''), 'foo=bar&baz=');
  $IS->(ixhash('foo' => ['1', '2']), 'foo[]=1&foo[]=2');
  $IS->(ixhash('foo' => 'bar', 'baz' => ['1', '2', '3']), 'foo=bar&baz[]=1&baz[]=2&baz[]=3');
  $IS->(ixhash('foo' => ['bar'], 'baz' => ['1', '2', '3']), 'foo[]=bar&baz[]=1&baz[]=2&baz[]=3');

  $IS->(ixhash('x' => { 'y' => { 'z' => '1' } }), 'x[y][z]=1');
  $IS->(ixhash('x' => { 'y' => { 'z' => ['1'] } }), 'x[y][z][]=1');
  $IS->(ixhash('x' => { 'y' => { 'z' => ['1', '2'] } }), 'x[y][z][]=1&x[y][z][]=2');
  $IS->(ixhash('x' => { 'y' => [{ 'z' => '1' }] }), 'x[y][][z]=1');
  $IS->(ixhash('x' => { 'y' => [{ 'z' => ['1'] }] }), 'x[y][][z][]=1');

  $IS->(ixhash('x' => { 'y' => [ixhash('z' => '1', 'w' => '2')] }), 'x[y][][z]=1&x[y][][w]=2');

  $IS->(ixhash('x' => { 'y' => [{ 'v' => { 'w' => '1' } }] }), 'x[y][][v][w]=1');

  $IS->(ixhash('x' => { 'y' => [ixhash('z' => '1', 'v' => { 'w' => '2' } )] }), 'x[y][][z]=1&x[y][][v][w]=2');

  $IS->(ixhash('x' => { 'y' => [{ 'z' => '1' }, { 'z' => '2' }] }), 'x[y][][z]=1&x[y][][z]=2');

  $IS->(ixhash('x' => { 'y' => [ixhash('z' => '1', 'w' => 'a'), ixhash('z' => '2', 'w' => '3')] }), 'x[y][][z]=1&x[y][][w]=a&x[y][][z]=2&x[y][][w]=3');

  $IS->({ "foo" => ["1", ["2"]] }, 'foo[]=1&foo[][]=2');
}

{
  # roundtrip
  my @tests = (
    { "foo" => nil, "bar" => "" },
    { "foo" => "bar", "baz" => "" },
    { "foo" => ["1", "2"] },
    { "foo" => "bar", "baz" => ["1", "2", "3"] },
    { "foo" => ["bar"], "baz" => ["1", "2", "3"] },
    { "foo" => ["1", "2"] },
    { "foo" => "bar", "baz" => ["1", "2", "3"] },
    { "x" => { "y" => { "z" => "1" } } },
    { "x" => { "y" => { "z" => ["1"] } } },
    { "x" => { "y" => { "z" => ["1", "2"] } } },
    { "x" => { "y" => [{ "z" => "1" }] } },
    { "x" => { "y" => [{ "z" => ["1"] }] } },
    { "x" => { "y" => [{ "z" => "1", "w" => "2" }] } },
    { "x" => { "y" => [{ "v" => { "w" => "1" } }] } },
    { "x" => { "y" => [{ "z" => "1", "v" => { "w" => "2" } }] } },
    { "x" => { "y" => [{ "z" => "1" }, { "z" => "2" }] } },
    { "x" => { "y" => [{ "z" => "1", "w" => "a" }, { "z" => "2", "w" => "3" }] } },
    { "foo" => ["1", ["2"]] },
   );

  foreach my $t (@tests) {
    if (not defined $t) {
      YATT::Lite::Breakpoint::breakpoint();
      next;
    }
    my $qs = YATT::Lite::Util->build_nested_query($t);
    is_deeply parse_nested_query($qs), $t, "roundtrip: ".terse_dump($t). " (qs: $qs)";
  }
}

done_testing();
