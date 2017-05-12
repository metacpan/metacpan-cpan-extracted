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



sub _create_node {
  my ($parent_node) = @_;
  no warnings 'redefine';
  # noop cluck so that tests look tidy
  local *XML::Constructor::cluck = sub {};
  return $CLASS->generate( parent_node => $parent_node );
}

# TESTS
{ # generate called without attributes 
  no warnings 'redefine';
  local *XML::Constructor::cluck = sub {};
  my $xml = XML::Constructor->generate();
  cmp_ok($xml->toString, 'eq', '</>', "parent_node not defined");
}

{ 
  my @tests_to_run  = (
    [ undef, '</>' ],
    [ 'aNamedEmptyTag', '<aNamedEmptyTag/>' ],
    [ ['nodeWithAttributes' => 'attr1', 'value1'], '<nodeWithAttributes attr1="value1"/>' ],
    [ XML::LibXML::Element->new('ElementNode'), '<ElementNode/>' ],
  );
  my $xml;

  for my $aTest (@tests_to_run) {
    my $xml = _create_node(@$aTest[0]);
    cmp_ok($xml->toString, 'eq', @$aTest[1], @$aTest[1]);
  }
}

{ # use node that already has children as parent_node
  my $node    = XML::LibXML::Element->new("level1");
  my $subnode = XML::LibXML::Element->new('level2');

  $subnode->appendText('developers deverlopers developers');
  $node->addChild($subnode);

  my $xml = XML::Constructor->generate(parent_node => $node, data => [{foo => 'bar'}]);
  my $expected = '<level1><level2>developers deverlopers developers</level2><foo>bar</foo></level1>';
  cmp_ok($xml->toString, 'eq', $expected, "parent node with pre-existing child" );
}

done_testing;
