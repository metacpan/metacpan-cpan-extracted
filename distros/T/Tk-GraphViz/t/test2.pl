#!/usr/bin/perl -w

use strict;
use lib '../blib/lib';
use Tk;
use Tk::GraphViz;

my $mw = new MainWindow ();
my $gv = $mw->Scrolled ( 'GraphViz',
			 -background => 'white',
			 -scrollbars => 'sw' )
  ->pack ( -expand => '1', -fill => 'both' );

$gv->bind ( 'node', '<Button-1>', sub {
	      my @tags = $gv->gettags('current');
	      push @tags, undef unless (@tags % 2) == 0;
	      my %tags = @tags;
	      printf "Clicked node: '%s' => %s\n", $tags{node}, $tags{label};
	    } );
$gv->bind ( 'edge', '<Button-1>', sub {
	      my @tags = $gv->gettags('current');
	      push @tags, undef unless (@tags % 2) == 0;
	      my %tags = @tags;
	      printf "Clicked edge: '%s' => %s\n", $tags{edge}, $tags{label};
	    } );

$gv->show ( shift );
$gv->createBindings(); # Default bindings

$gv->itemconfigure('edge', -activefill => 'green' );

MainLoop;
