#!/usr/bin/perl -w
use strict;
use Test::More;
use lib 't';
use testlib;

# This test file tests the abstraction
# of XML::LibXML and XML::XPath nodes

my $HTML = '<html><body onload="foo()">test</body></html>';

sub run {
  my ($implementation) = @_;
  SKIP: {
    skip "Tests irrelevant for pure Perl implementation", 4
      if $implementation eq 'PurePerl';
    use_ok('Test::HTML::Content');
    my $tree = Test::HTML::Content::__get_node_tree($HTML, '/html/body');
    isn't( $tree, undef, "Got body node");
    foreach my $node ($tree->get_nodelist) {
      is( Test::HTML::Content::__get_node_content($node,'onload'), 'foo()', 'onload attribute');
      is( Test::HTML::Content::__get_node_content($node,'_content'), 'test','_content pseudo attribute');
    };
  };
};

runtests( 4,\&run );
