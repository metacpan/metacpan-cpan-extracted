#!/usr/bin/perl

use lib( ".." );
use Treemap;
use Treemap::Input::Dir;
use Treemap::Output::PrintedText;

$input = new Treemap::Input::Dir;
$input->load( "../" );

$output = new Treemap::Output::PrintedText;

$treemap = new Treemap( INPUT=>$input, OUTPUT=>$output );
$treemap->map();
