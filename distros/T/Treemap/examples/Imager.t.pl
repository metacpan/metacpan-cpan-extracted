#!/usr/bin/perl

use lib( ".." );
use Data::Dumper;
use Treemap::Output::Imager;

$output = new Treemap::Output::Imager;

# Co-ordinates are: x1, y1, x2, y2, colour 
$output->rect(0,0,99,99,hex("0x00FF00") );
$output->rect(100,100,199,199,hex("0xFF0000") );
$output->text(0,0,99,99,"level2");
$output->text(100,100,199,199,"level1");
$output->save($ARGV[0]);

1;
