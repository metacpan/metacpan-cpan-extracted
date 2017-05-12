#!/usr/bin/perl -w
use strict;

use t::lib::T;
use t::lib::U;

my $xml = <<'END_XML';
<?xml version="1.0"?>
<shopping>
    <item>sample</item>
</shopping>
END_XML

ok( my $compiler = XML::Writer::Compiler->new, 'XML::Writer::Compiler instance' );

my $tree = XML::TreeBuilder->new({ 'NoExpand' => 0, 'ErrorContext' => 0 });
$tree->parse($xml);

my $firstdepth = 0;
my $class = 't::lib::My::Shopping';
my $pkg = $compiler->buildclass($class => $tree, $firstdepth);

package Temp;

use Moose;
extends qw(t::lib::My::Shopping);

sub _tag_shopping_item {
  my($self)=@_;

  for my $item qw(bread butter beans) {
    $self->writer->dataElement('item', $item);
  }
}

1;

package main;

my $xmlgen = Temp->new;

my $xml = $xmlgen->xml->string->value;
my $exp =
'<shopping><item>bread</item><item>butter</item><item>beans</item></shopping>';

is_xml( $xml, $exp, 'test xml generation' );
done_testing;
