#!/usr/bin/perl

use lib( ".." );
use Treemap;
use Treemap::Input::XML;
use Treemap::Output::Imager;

$input = new Treemap::Input::XML;
$input->load( "XML.xml" );

$output = new Treemap::Output::Imager( WIDTH=>1024, HEIGHT=>768, FONT_FILE=>'../ImUgly.ttf' );

$treemap = new Treemap( INPUT=>$input, OUTPUT=>$output );
$treemap->map();
$output->save($ARGV[0]);
