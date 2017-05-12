use strict;
use warnings FATAL => 'all';

use Test::More qw(no_plan);

use Web::Dispatch::Parser;

my $dp = Web::Dispatch::Parser->new;

{
  my $all = $dp->parse('');

  is_deeply(
    [ $all->({ REQUEST_METHOD => 'GET' }) ],
    [ {} ],
    'GET matches'
  );

  is_deeply(
    [ $all->({ REQUEST_METHOD => 'POST' }) ],
    [ {} ],
    'POST matches'
  );
};

{
  my $get = $dp->parse('GET');

  is_deeply(
    [ $get->({ REQUEST_METHOD => 'GET' }) ],
    [ {} ],
    'GET matches'
  );

  is_deeply(
    [ $get->({ REQUEST_METHOD => 'POST' }) ],
    [],
    'POST does not match'
  );
}

{
  my $html = $dp->parse('.html');

  is_deeply(
    [ $html->({ PATH_INFO => '/foo/bar.html' }) ],
    [ { } ],
    '.html matches'
  );

  is_deeply(
    [ $html->({ PATH_INFO => '/foo/bar.xml' }) ],
    [],
    '.xml does not match .html'
  );
}

{
  my $any_ext = $dp->parse('.*');

  is_deeply(
    [ $any_ext->({ PATH_INFO => '/foo/bar.html' }) ],
    [ { }, 'html' ],
    '.html matches .* and extension returned'
  );

  is_deeply(
    [ $any_ext->({ PATH_INFO => '/foo/bar' }) ],
    [],
    'no extension does not match .*'
  );
}

{
  my $slash = $dp->parse('/');

  is_deeply(
    [ $slash->({ PATH_INFO => '/' }) ],
    [ {} ],
    '/ matches /'
  );

  is_deeply(
    [ $slash->({ PATH_INFO => '/foo' }) ],
    [ ],
    '/foo does not match /'
  );
}

{
  my $post = $dp->parse('/post/*');

  is_deeply(
    [ $post->({ PATH_INFO => '/post/one' }) ],
    [ {}, 'one' ],
    '/post/one parses out one'
  );

  is_deeply(
    [ $post->({ PATH_INFO => '/post/one/' }) ],
    [],
    '/post/one/ does not match'
  );

  is_deeply(
    [ $post->({ PATH_INFO => '/post/one.html' }) ],
    [ {}, 'one' ],
    '/post/one.html still parses out one'
  );
}

{
  my $post = $dp->parse('/foo-bar/*');

  is_deeply(
    [ $post->({ PATH_INFO => '/foo-bar/one' }) ],
    [ {}, 'one' ],
    '/foo-bar/one parses out one'
  );

  is_deeply(
    [ $post->({ PATH_INFO => '/foo-bar/one/' }) ],
    [],
    '/foo-bar/one/ does not match'
  );
}

{
  my $combi = $dp->parse('GET+/post/*');

  is_deeply(
    [ $combi->({ PATH_INFO => '/post/one', REQUEST_METHOD => 'GET' }) ],
    [ {}, 'one' ],
    '/post/one parses out one'
  );

  is_deeply(
    [ $combi->({ PATH_INFO => '/post/one/', REQUEST_METHOD => 'GET' }) ],
    [],
    '/post/one/ does not match'
  );

  is_deeply(
    [ $combi->({ PATH_INFO => '/post/one', REQUEST_METHOD => 'POST' }) ],
    [],
    'POST /post/one does not match'
  );
}

{
  my $or = $dp->parse('GET|POST');

  foreach my $meth (qw(GET POST)) {

    is_deeply(
      [ $or->({ REQUEST_METHOD => $meth }) ],
      [ {} ],
      'GET|POST matches method '.$meth
    );
  }

  is_deeply(
    [ $or->({ REQUEST_METHOD => 'PUT' }) ],
    [],
    'GET|POST does not match PUT'
  );
}

{
  my $or = $dp->parse('GET|POST|DELETE');

  foreach my $meth (qw(GET POST DELETE)) {

    is_deeply(
      [ $or->({ REQUEST_METHOD => $meth }) ],
      [ {} ],
      'GET|POST|DELETE matches method '.$meth
    );
  }

  is_deeply(
    [ $or->({ REQUEST_METHOD => 'PUT' }) ],
    [],
    'GET|POST|DELETE does not match PUT'
  );
}

{
  my $nest = $dp->parse('(GET+/foo)|POST');

  is_deeply(
    [ $nest->({ PATH_INFO => '/foo', REQUEST_METHOD => 'GET' }) ],
    [ {} ],
    '(GET+/foo)|POST matches GET /foo'
  );

  is_deeply(
    [ $nest->({ PATH_INFO => '/bar', REQUEST_METHOD => 'GET' }) ],
    [],
    '(GET+/foo)|POST does not match GET /bar'
  );

  is_deeply(
    [ $nest->({ PATH_INFO => '/bar', REQUEST_METHOD => 'POST' }) ],
    [ {} ],
    '(GET+/foo)|POST matches POST /bar'
  );

  is_deeply(
    [ $nest->({ PATH_INFO => '/foo', REQUEST_METHOD => 'PUT' }) ],
    [],
    '(GET+/foo)|POST does not match PUT /foo'
  );
}

{
  my $spec = '(GET+/foo)|(POST+/foo)';
  my $nest = $dp->parse($spec);

  for my $method (qw( GET POST )) {
      is_deeply(
        [ $nest->({ PATH_INFO => '/foo', REQUEST_METHOD => $method }) ],
        [ {} ],
        "$spec matches $method /foo"
      );
      is_deeply(
        [ $nest->({ PATH_INFO => '/bar', REQUEST_METHOD => $method }) ],
        [],
        "$spec does not match $method /bar"
      );
  }

  is_deeply(
    [ $nest->({ PATH_INFO => '/foo', REQUEST_METHOD => 'PUT' }) ],
    [],
    "$spec does not match PUT /foo"
  );
}

{
  local $@;
  ok(
    !eval { $dp->parse('/foo+(GET'); 1 },
    'Death with missing closing )'
  );
  my $err = q{
    /foo+(GET
         ^
  };
  (s/^\n//s,s/\n  $//s,s/^    //mg) for $err;
  like(
    $@,
    qr{\Q$err\E},
    "Error $@ matches\n${err}\n"
  );
}

{
  my $not = $dp->parse('!.html+.*');

  is_deeply(
    [ $not->({ PATH_INFO => '/foo.xml' }) ],
    [ {}, 'xml' ],
    '!.html+.* matches /foo.xml'
  );

  is_deeply(
    [ $not->({ PATH_INFO => '/foo.html' }) ],
    [],
    '!.html+.* does not match /foo.html'
  );

  is_deeply(
    [ $not->({ PATH_INFO => '/foo' }) ],
    [],
    '!.html+.* does not match /foo'
  );
}

{
  my $ext = $dp->parse('/foo.bar');

  is_deeply(
    [ $ext->({ PATH_INFO => '/foo.bar' }) ],
    [ {} ],
    '/foo.bar matches /foo.bar'
  );

  is_deeply(
    [ $ext->({ PATH_INFO => '/foo.bar.ext' }) ],
    [ {} ],
    '/foo.bar matches /foo.bar.ext'
  );

  is_deeply(
    [ $ext->({ PATH_INFO => '/foo.notbar' }) ],
    [],
    '/foo.bar does not match /foo.notbar'
  );
}

{
  my $sub = $dp->parse('/foo/*/...');

  is_deeply(
    [ $sub->({ PATH_INFO => '/foo/1/bar' }) ],
    [ { PATH_INFO => '/bar', SCRIPT_NAME => '/foo/1' }, 1 ],
    '/foo/*/... matches /foo/1/bar and strips to /bar'
  );

  is_deeply(
    [ $sub->({ PATH_INFO => '/foo/1/' }) ],
    [ { PATH_INFO => '/', SCRIPT_NAME => '/foo/1' }, 1 ],
    '/foo/*/... matches /foo/1/bar and strips to /'
  );

  is_deeply(
    [ $sub->({ PATH_INFO => '/foo/1' }) ],
    [],
    '/foo/*/... does not match /foo/1 (no trailing /)'
  );
}

{
  my $sub = $dp->parse('/foo/**/belief');
  my $match = 'barred/beyond';
  is_deeply(
    [ $sub->({ PATH_INFO => "/foo/${match}/belief" }) ],
    [ {}, $match ],
    "/foo/**/belief matches /foo/${match}/belief"
  );
}

{
  my $match = '~';
  my $sub = $dp->parse($match);

  is_deeply(
    [ $sub->({ PATH_INFO => '/foo' }) ],
    [],
    "$match does not match /foo"
  );

  is_deeply(
    [ $sub->({ PATH_INFO => '' }) ],
    [ {} ],
    "$match matches empty path with empty env"
  );
}

{
  my $match = '/foo...';
  my $sub = $dp->parse($match);

  is_deeply(
    [ $sub->({ PATH_INFO => '/foobar' }) ],
    [],
    "$match does not match /foobar"
  );

  is_deeply(
    [ $sub->({ PATH_INFO => '/foo/bar' }) ],
    [ { PATH_INFO => '/bar', SCRIPT_NAME => '/foo' } ],
    "$match matches /foo/bar and strips to /bar"
  );

  is_deeply(
    [ $sub->({ PATH_INFO => '/foo/' }) ],
    [ { PATH_INFO => '/', SCRIPT_NAME => '/foo' } ],
    "$match matches /foo/ and strips to /"
  );

  is_deeply(
    [ $sub->({ PATH_INFO => '/foo' }) ],
    [ { PATH_INFO => '', SCRIPT_NAME => '/foo' } ],
    "$match matches /foo and strips to empty path"
  );
}

{
  my @dot_pairs = (
    [ '/one/*' => 'two' ],
    [ '/one/*.*' => 'two.three' ],
    [ '/**' => 'one/two' ],
    [ '/**.*' => 'one/two.three' ],
  );

  foreach my $p (@dot_pairs) {
    is_deeply(
      [ $dp->parse($p->[0])->({ PATH_INFO => '/one/two.three' }) ],
      [ {}, $p->[1] ],
      "${\$p->[0]} matches /one/two.three and returns ${\$p->[1]}"
    );
  }
}

{
  my @named = (
    [ '/foo/*:foo_id' => '/foo/1' => { foo_id => 1 } ],
    [ '/foo/:foo_id' => '/foo/1' => { foo_id => 1 } ],
    [ '/foo/:id/**:rest' => '/foo/id/rest/of/the/path.ext'
      => { id => 'id', rest => 'rest/of/the/path' } ],
    [ '/foo/:id/**.*:rest' => '/foo/id/rest/of/the/path.ext'
      => { id => 'id', rest => 'rest/of/the/path.ext' } ],
  );
  foreach my $n (@named) {
    is_deeply(
      [ $dp->parse($n->[0])->({ PATH_INFO => $n->[1] }) ],
      [ {}, $n->[2] ],
      "${\$n->[0]} matches ${\$n->[1]} with correct captures"
    );
  }
}

#
# query string
#

my $q = 'foo=FOO&bar=BAR1&baz=one+two&quux=QUUX1&quux=QUUX2'
  .'&foo.bar=FOOBAR1&foo.bar=FOOBAR2&foo.baz=FOOBAZ'
  .'&bar=BAR2&quux=QUUX3&evil=%2F';

my %all_single = (
  foo => 'FOO',
  bar => 'BAR2',
  baz => 'one two',
  quux => 'QUUX3',
  evil => '/',
  'foo.baz' => 'FOOBAZ',
  'foo.bar' => 'FOOBAR2',
);

my %all_multi = (
  foo => [ 'FOO' ],
  bar => [ qw(BAR1 BAR2) ],
  baz => [ 'one two' ],
  quux => [ qw(QUUX1 QUUX2 QUUX3) ],
  evil => [ '/' ],
  'foo.baz' => [ 'FOOBAZ' ],
  'foo.bar' => [ qw(FOOBAR1 FOOBAR2) ],
);

foreach my $lose ('?foo=','?:foo=','?@foo=','?:@foo=') {
  my $foo = $dp->parse($lose);

  is_deeply(
    [ $foo->({ QUERY_STRING => '' }) ],
    [],
    "${lose} fails with no query"
  );

  is_deeply(
    [ $foo->({ QUERY_STRING => 'bar=baz' }) ],
    [],
    "${lose} fails with query missing foo key"
  );
}

foreach my $win (
  [ '?foo=' => 'FOO' ],
  [ '?:foo=' => { foo => 'FOO' } ],
  [ '?spoo~' => undef ],
  [ '?:spoo~' => {} ],
  [ '?@spoo~' => [] ],
  [ '?:@spoo~' => { spoo => [] } ],
  [ '?bar=' => 'BAR2' ],
  [ '?:bar=' => { bar => 'BAR2' } ],
  [ '?@bar=' => [ qw(BAR1 BAR2) ] ],
  [ '?:@bar=' => { bar => [ qw(BAR1 BAR2) ] } ],
  [ '?foo=&@bar=' => 'FOO', [ qw(BAR1 BAR2) ] ],
  [ '?foo=&:@bar=' => 'FOO', { bar => [ qw(BAR1 BAR2) ] } ],
  [ '?:foo=&:@bar=' => { foo => 'FOO', bar => [ qw(BAR1 BAR2) ] } ],
  [ '?:baz=&:evil=' => { baz => 'one two', evil => '/' } ],
  [ '?*' => \%all_single ],
  [ '?@*' => \%all_multi ],
  [ '?foo=&@*' => 'FOO', \%all_multi ],
  [ '?:foo=&@*' => { %all_multi, foo => 'FOO' } ],
  [ '?:@bar=&*' => { %all_single, bar => [ qw(BAR1 BAR2) ] } ],
  [ '?foo.baz=' => 'FOOBAZ' ],
  [ '?:foo.baz=' => { 'foo.baz' => 'FOOBAZ' } ],
  [ '?foo.bar=' => 'FOOBAR2' ],
  [ '?:foo.bar=' => { 'foo.bar' => 'FOOBAR2' } ],
  [ '?@foo.bar=' => [ qw(FOOBAR1 FOOBAR2) ] ],
  [ '?:@foo.bar=' => { 'foo.bar' => [ qw(FOOBAR1 FOOBAR2) ] } ],
) {
  my ($spec, @res) = @$win;
  my $match = $dp->parse($spec);
  #use Data::Dump::Streamer; warn Dump($match);
  is_deeply(
    [ $match->({ QUERY_STRING => $q }) ],
    [ {}, @res ],
    "${spec} matches correctly"
  );
}

#
# /path/info/ + query string
#

foreach my $lose2 ('/foo/bar/+?foo=','/foo/bar/+?:foo=','/foo/bar/+?@foo=','/foo/bar/+?:@foo=') {
  my $foo = $dp->parse($lose2);

  is_deeply(
    [ $foo->({ PATH_INFO => '/foo/bar/', QUERY_STRING => '' }) ],
    [ ],
    "${lose2} fails with no query"
  );

  is_deeply(
    [ $foo->({ PATH_INFO => '/foo/bar/', QUERY_STRING => 'bar=baz' }) ],
    [ ],
    "${lose2} fails with query missing foo key"
  );
}

foreach my $win2 (
  [ '/foo/bar/+?foo=' => 'FOO' ],
  [ '/foo/bar/+?:foo=' => { foo => 'FOO' } ],
  [ '/foo/bar/+?spoo~' => undef ],
  [ '/foo/bar/+?:spoo~' => {} ],
  [ '/foo/bar/+?@spoo~' => [] ],
  [ '/foo/bar/+?:@spoo~' => { spoo => [] } ],
  [ '/foo/bar/+?bar=' => 'BAR2' ],
  [ '/foo/bar/+?:bar=' => { bar => 'BAR2' } ],
  [ '/foo/bar/+?@bar=' => [ qw(BAR1 BAR2) ] ],
  [ '/foo/bar/+?:@bar=' => { bar => [ qw(BAR1 BAR2) ] } ],
  [ '/foo/bar/+?foo=&@bar=' => 'FOO', [ qw(BAR1 BAR2) ] ],
  [ '/foo/bar/+?foo=&:@bar=' => 'FOO', { bar => [ qw(BAR1 BAR2) ] } ],
  [ '/foo/bar/+?:foo=&:@bar=' => { foo => 'FOO', bar => [ qw(BAR1 BAR2) ] } ],
  [ '/foo/bar/+?:baz=&:evil=' => { baz => 'one two', evil => '/' } ],
  [ '/foo/bar/+?*' => \%all_single ],
  [ '/foo/bar/+?@*' => \%all_multi ],
  [ '/foo/bar/+?foo=&@*' => 'FOO', \%all_multi ],
  [ '/foo/bar/+?:foo=&@*' => { %all_multi, foo => 'FOO' } ],
  [ '/foo/bar/+?:@bar=&*' => { %all_single, bar => [ qw(BAR1 BAR2) ] } ],
  [ '/foo/bar/+?foo.baz=' => 'FOOBAZ' ],
  [ '/foo/bar/+?:foo.baz=' => { 'foo.baz' => 'FOOBAZ' } ],
  [ '/foo/bar/+?foo.bar=' => 'FOOBAR2' ],
  [ '/foo/bar/+?:foo.bar=' => { 'foo.bar' => 'FOOBAR2' } ],
  [ '/foo/bar/+?@foo.bar=' => [ qw(FOOBAR1 FOOBAR2) ] ],
  [ '/foo/bar/+?:@foo.bar=' => { 'foo.bar' => [ qw(FOOBAR1 FOOBAR2) ] } ],
) {
  my ($spec, @res) = @$win2;
  my $match = $dp->parse($spec);
  # use Data::Dump::Streamer; warn Dump($match);
  is_deeply(
    [ $match->({ PATH_INFO => '/foo/bar/', QUERY_STRING => $q }) ],
    [ {}, @res ],
    "${spec} matches correctly"
  );
}

#
# /path/info + query string
#

foreach my $lose3 ('/foo/bar+?foo=','/foo/bar+?:foo=','/foo/bar+?@foo=','/foo/bar+?:@foo=') {
  my $foo = $dp->parse($lose3);

  is_deeply(
    [ $foo->({ PATH_INFO => '/foo/bar', QUERY_STRING => '' }) ],
    [ ],
    "${lose3} fails with no query"
  );

  is_deeply(
    [ $foo->({ PATH_INFO => '/foo/bar', QUERY_STRING => 'bar=baz' }) ],
    [ ],
    "${lose3} fails with query missing foo key"
  );
}

foreach my $win3 (
  [ '/foo/bar+?foo=' => 'FOO' ],
  [ '/foo/bar+?:foo=' => { foo => 'FOO' } ],
  [ '/foo/bar+?spoo~' => undef ],
  [ '/foo/bar+?:spoo~' => {} ],
  [ '/foo/bar+?@spoo~' => [] ],
  [ '/foo/bar+?:@spoo~' => { spoo => [] } ],
  [ '/foo/bar+?bar=' => 'BAR2' ],
  [ '/foo/bar+?:bar=' => { bar => 'BAR2' } ],
  [ '/foo/bar+?@bar=' => [ qw(BAR1 BAR2) ] ],
  [ '/foo/bar+?:@bar=' => { bar => [ qw(BAR1 BAR2) ] } ],
  [ '/foo/bar+?foo=&@bar=' => 'FOO', [ qw(BAR1 BAR2) ] ],
  [ '/foo/bar+?foo=&:@bar=' => 'FOO', { bar => [ qw(BAR1 BAR2) ] } ],
  [ '/foo/bar+?:foo=&:@bar=' => { foo => 'FOO', bar => [ qw(BAR1 BAR2) ] } ],
  [ '/foo/bar+?:baz=&:evil=' => { baz => 'one two', evil => '/' } ],
  [ '/foo/bar+?*' => \%all_single ],
  [ '/foo/bar+?@*' => \%all_multi ],
  [ '/foo/bar+?foo=&@*' => 'FOO', \%all_multi ],
  [ '/foo/bar+?:foo=&@*' => { %all_multi, foo => 'FOO' } ],
  [ '/foo/bar+?:@bar=&*' => { %all_single, bar => [ qw(BAR1 BAR2) ] } ],
  [ '/foo/bar+?foo.baz=' => 'FOOBAZ' ],
  [ '/foo/bar+?:foo.baz=' => { 'foo.baz' => 'FOOBAZ' } ],
  [ '/foo/bar+?foo.bar=' => 'FOOBAR2' ],
  [ '/foo/bar+?:foo.bar=' => { 'foo.bar' => 'FOOBAR2' } ],
  [ '/foo/bar+?@foo.bar=' => [ qw(FOOBAR1 FOOBAR2) ] ],
  [ '/foo/bar+?:@foo.bar=' => { 'foo.bar' => [ qw(FOOBAR1 FOOBAR2) ] } ],
) {
  my ($spec, @res) = @$win3;
  my $match = $dp->parse($spec);
  # use Data::Dump::Streamer; warn Dump($match);
  is_deeply(
    [ $match->({ PATH_INFO => '/foo/bar', QUERY_STRING => $q }) ],
    [ {}, @res ],
    "${spec} matches correctly"
  );
}
