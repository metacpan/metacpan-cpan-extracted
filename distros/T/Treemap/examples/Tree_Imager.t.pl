#!/usr/bin/perl

use lib( ".." );
use Treemap;
use Treemap::Input::Dir;
use Treemap::Output::Imager;

$input = new Treemap::Input::Dir;
$input->load( "../" );

$output = new Treemap::Output::Imager( WIDTH=>1024, HEIGHT=>768, FONT_FILE=>'../ImUgly.ttf' );

$treemap = new Treemap( INPUT=>$input, OUTPUT=>$output );
$treemap->map();
$output->save($ARGV[0]);
