#!/usr/bin/perl

use lib( ".." );
use Treemap::Squarified;
use Treemap::Input::XML;
use Treemap::Output::Imager;

$XML = $ARGV[1] || "XML.xml";
$input = new Treemap::Input::XML;
print "Loading $XML...\n";
$input->load( $XML );

$output = new Treemap::Output::Imager( WIDTH=>1024, HEIGHT=>768, FONT_FILE=>'../ImUgly.ttf' );

$treemap = new Treemap::Squarified( INPUT=>$input, OUTPUT=>$output );
$treemap->map();
$output->save($ARGV[0]);
