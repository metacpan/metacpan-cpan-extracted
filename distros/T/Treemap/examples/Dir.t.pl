#!/usr/bin/perl

use lib( ".." );
use Data::Dumper;
use Treemap::Input::Dir;

$dir = new Treemap::Input::Dir;
$dir->load( "../" );

print Dumper( $dir->treedata );

1;
