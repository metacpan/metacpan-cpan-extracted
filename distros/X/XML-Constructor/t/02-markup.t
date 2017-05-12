#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use XML::LibXML;

our $CLASS;

BEGIN {
  $CLASS  = 'XML::Constructor';
  use_ok( $CLASS );
}

our $rootNode = 'rootNode';

sub _test_markup {
  my ($markup, $expected, $comment, $parent_node) = @_;

  $parent_node ||= $rootNode;
  my $node  = $CLASS->generate( data => $markup, parent_node => $parent_node );

  cmp_ok($node->toString, 'eq', $expected, $comment || $expected);
}

{ # basic markup tests
  my ($markup, $expected);
  $markup   = [];
  $expected = '<rootNode/>';
  _test_markup($markup, $expected);

  $markup   = [ \'bar' ];
  $expected = '<rootNode>bar</rootNode>';
  _test_markup($markup, $expected);

  $markup   = [ {foo => 'bar'} ];
  $expected = '<rootNode><foo>bar</foo></rootNode>';
  _test_markup($markup, $expected);

  $markup   = [ [foo => \'bar'] ];
  $expected = '<rootNode><foo>bar</foo></rootNode>';
  _test_markup($markup, $expected);

  $markup   = [ [foo => 'bar', 'baz'] ];
  $expected = '<rootNode><foo bar="baz"/></rootNode>';
  _test_markup($markup, $expected);
}

{ # combined markup
  my ($markup, $expected);

  $markup   = [ \'bar', { this => 'that' } ];
  $expected = '<rootNode>bar<this>that</this></rootNode>';
 _test_markup($markup, $expected);

  $markup   = [ \'bar', [ this => 'that' ] ];
  $expected = '<rootNode>bar<this that=""/></rootNode>';
 _test_markup($markup, $expected);

  $markup   = [ \'string', { 'level1' => [ level2 => \'string2' ] } ];
  $expected = '<rootNode>string<level1><level2>string2</level2></level1></rootNode>';
 _test_markup($markup, $expected);

  $markup   = [[ level1 => \'string1', 'attr1', 'attr1val' ]];
  $expected = '<rootNode><level1 attr1="attr1val">string1</level1></rootNode>';
 _test_markup($markup, $expected);

  $markup   = [[ level1 => \'string1', 'attr1', 'attr1val', \'string2' ]];
  $expected = '<rootNode><level1 attr1="attr1val">string1string2</level1></rootNode>';
 _test_markup($markup, $expected);

  $markup   = [[ 'h:table' => [ 'h:tr' => { 'h:td' => 'Apples' } ] ] ];
  $expected = '<rootNode><h:table><h:tr><h:td>Apples</h:td></h:tr></h:table></rootNode>';
 _test_markup($markup, $expected);

  $markup   = [[ 'h:table' => [ 'h:tr' => { 'h:td' => 'Apples' } ] ] ];
  $expected = qq'<?xml version="1.0"?>\n<h:table><h:tr><h:td>Apples</h:td></h:tr></h:table>\n';
 _test_markup($markup, $expected,"parent_node is XML::LibXML::Document",XML::LibXML::Document->new);

  # real world example
  # ignore #'s in qw
  no warnings 'syntax';

  $markup   = [
    { title => 'YouTube Videos'},
    { logo  => 'http://www.youtube.com/img/pic_youtubelogo_123x63.gif' },

    # lazily define attributes on element
    [ link => qw( rel     alternate
                  type    text/html
                  href    http://www.youtube.com)],

    [ link => qw( rel     http://schemas.google.com/g/2005#feed
                  type    application/atom+xml
                  href    http://gdata.youtube.com/feeds/api/videos?v=2)],

    [ link => qw( rel     http://schemas.google.com/g/2005#batch
                  type    application/atom+xml
                  href    http://gdata.youtube.com/feeds/api/videos/batch?v=2)],

    [ author => {name => 'YouTube'},{uri => 'http://www.youtube.com/'} ]
  ];
  $expected = '<rootNode>'. 
              '<title>YouTube Videos</title>'.
              '<logo>http://www.youtube.com/img/pic_youtubelogo_123x63.gif</logo>'.
              '<link rel="alternate" type="text/html" href="http://www.youtube.com"/>'.
              '<link rel="http://schemas.google.com/g/2005#feed" type="application/atom+xml" href="http://gdata.youtube.com/feeds/api/videos?v=2"/>'.
              '<link rel="http://schemas.google.com/g/2005#batch" type="application/atom+xml" href="http://gdata.youtube.com/feeds/api/videos/batch?v=2"/>'.
              '<author>'.
              '<name>YouTube</name>'.
              '<uri>http://www.youtube.com/</uri>'.
              '</author></rootNode>';
 _test_markup($markup, $expected,"real world example");
}

done_testing;
