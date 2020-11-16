#!/usr/bin/perl -w

use strict;
use lib '../blib/lib';
use Tk::GraphViz;
use Tk;
use GraphViz;

my $mw = MainWindow->new();

my $gv = $mw->Scrolled ( 'GraphViz',
			-background => 'white',
			 -scrollbars => 'sw' )
  ->pack ( -expand => '1', -fill => 'both' );

my $entryText = '';

my $entry = $mw->Entry ( -width => 80, -textvariable => \$entryText )
  ->pack ( -side => 'bottom', -expand => '1', -fill => 'x',
	   -pady => 2 );

my $g = new GraphViz;
$g->add_node ('a');
$g->add_node ('b', shape => 'box', foo=> 'xyz' );
$g->add_node ('c', shape => 'house' );
$g->add_edge ('a' => 'b' );
$g->add_edge ('b' => 'c' );
$g->add_edge ('c' => 'a', label => 'c->a' );

$g->add_node ( '1', color => 'red', fillcolor=>'cyan',
	       style=>'bold', cluster => 'xyz' );
$g->add_node ( '2', color => 'blue', cluster => 'xyz' );
$gv->show ( $g );
$gv->createBindings();
#$gv->show ( 'test1.dot' );

$gv->bind ( 'node', '<Any-Enter>', sub {
	      my @tags = $gv->gettags('current');
	      $entryText = "@tags";
	    } );

$gv->bind ( 'edge', '<Any-Enter>', sub {
	      my @tags = $gv->gettags('current');
	      $entryText = "@tags";
	    } );

$gv->bind ( 'all', '<Any-Leave>', sub { $entryText = ''; } );

MainLoop;

