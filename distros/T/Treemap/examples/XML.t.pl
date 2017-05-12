#!/usr/bin/perl

use lib( ".." );
use Data::Dumper;
use Treemap::Input::XML;

$dir = new Treemap::Input::XML;
$dir->load( "./XML.xml" );

print Dumper( $dir->treedata );

1;
