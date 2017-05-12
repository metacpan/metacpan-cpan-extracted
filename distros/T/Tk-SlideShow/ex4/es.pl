#!/usr/local/bin/perl5 -w
use strict;
use Tk;

my $mw = MainWindow->new;

my $c = $mw->Canvas->pack;

my $menu = $mw->Menu;

my $fr = $menu->Scrolled('Listbox')->pack;



$menu->configure(-takefocus => 1);

$fr->insert('end',grep(-T $_,<*>));

my $lb = $fr->Subwidget('listbox');
$lb->bind('<1>' => sub {
	    print $lb->curselection . "\n";
	    $menu->unpost;
	  });

$c->Tk::bind('<1>',sub { 
	       my $e = (shift)->XEvent;
	       $menu->post($e->X,$e->Y);
	     } );

MainLoop;

