#!/usr/bin/perl -w

use strict;
use File::Spec::Functions 'catfile';

# Synopsis.

#  use Test::More tests => 28; # Use when PerlX::MethodCallWithBlock tests uncommented.
  use Test::More tests => 22;
  use Test::XPath;

  my $xml = <<'XML';
  <html>
    <head>
      <title>Hello</title>
      <style type="text/css" src="foo.css"></style>
      <style type="text/css" src="bar.css"></style>
    </head>
    <body>
      <h1>Welcome to my lair.</h1>
    </body>
  </html>
XML

  my $tx = Test::XPath->new( xml => $xml );

  $tx->ok( '/html/head', 'There should be a head' );
  $tx->is( '/html/head/title', 'Hello', 'The title should be correct' );

  # Recursing into a document:
  my @css = qw(foo.css bar.css);
  $tx->ok( '/html/head/style[@type="text/css"]', sub {
      my $css = shift @css;
      shift->is( './@src', $css, "Style src should be $css");
  }, 'Should have style' );

  # Better yet, use PerlX::MethodCallWithBlock:
  # @css = qw(foo.css bar.css);
  # use PerlX::MethodCallWithBlock;
  # $tx->ok( '/html/head/style[@type="text/css"]', 'Should have style' ) {
  #     my $css = shift @css;
  #     shift->is( './@src', $css, "Style src should be $css");
  # };

# ok()

$tx = Test::XPath->new( xml => '<foo><bar><title>Welcome</title></bar></foo>');

  $tx->ok( '//foo/bar', 'Should have bar element under foo element' );
  $tx->ok( 'contains(//title, "Welcome")', 'Title should "Welcome"' );

# ok() recursive.

$tx = Test::XPath->new( xml => '<assets><story id="1" /><story id="2" /></assets>');

  my $i = 0;
  $tx->ok( '//assets/story', sub {
      shift->is('./@id', ++$i, "ID should be $i in story $i");
  }, 'Should have story elements' );

  # use PerlX::MethodCallWithBlock;
  # $i = 0;
  # $tx->ok( '//assets/story', 'Should have story elements' ) {
  #     shift->is('./@id', ++$i, "ID should be $i in story $i");
  # };

# ok() deep atom example.

$tx = Test::XPath->new( file => catfile(qw(t atom.xml)) );


  $tx->ok( '/feed/entry', sub {
      $_->ok( './title', 'Should have a title' );
      $_->ok( './author', sub {
          $_->is( './name',  'Mark Pilgrim',        'Mark should be author' );
          $_->is( './uri',   'http://example.org/', 'URI should be correct' );
          $_->is( './email', 'f8dy@example.com',    'Email should be right' );
      }, 'Should have author elements' );
  }, 'Should have entry elments' );

# xpc, adding an XPath function.

  $tx->xpc->registerFunction( grep => sub {
      my ($nodelist, $regex) =  @_;
      my $result = XML::LibXML::NodeList->new;
      for my $node ($nodelist->get_nodelist) {
          $result->push($node) if $node->textContent =~ $regex;
      }
      return $result;
  } );

  $tx->ok(
      'grep(//author/email, "@example[.](?:com|org)$")',
      'Should have example email'
  );
