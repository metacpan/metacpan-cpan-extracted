#!/usr/bin/perl

use lib( ".." );
use Treemap::Squarified;
use Treemap::Input::Dir;
use Treemap::Output::Imager;

$input = new Treemap::Input::Dir;
$FN = $ARGV[0] || "./test.png";
$DIR = $ARGV[1] || "../";
$input->load( $DIR );

$output = new Treemap::Output::Imager( WIDTH=>1024, HEIGHT=>768, BORDER_COLOUR=>11184810 );

$treemap = new Treemap::Squarified( INPUT=>$input, OUTPUT=>$output, PADDING=>10, SPACING=>0 );
$treemap->map();
$output->save($FN);
