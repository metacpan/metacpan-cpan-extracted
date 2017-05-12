#!/usr/local/bin/perl -w
# -*- perl -*-

#
# $Id: 1.pl,v 1.8 1998/08/28 00:41:44 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 1997,1998 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

use Tk;
use Tk::HistEntry;
use strict;

my $top = new MainWindow;

my($foo, $bla, $blubber);

my $f = $top->Frame->grid(-row => 0, -column => 0,  -sticky => 'n');
my $lb = $top->Scrolled('Listbox', -scrollbars => 'osoe'
		       )->grid(-row => 0, -column => 1);
$f->Label(-text => 'HistEntry')->pack;
my $b = $f->HistEntry(-textvariable => \$foo)->pack;
my $bb = $f->Button(-text => 'Add current',
		    -command => sub {
			return unless $foo;
			$b->historyAdd($foo);
			$lb->delete(0, 'end');
			foreach ($b->history) {
			    $lb->insert('end', $_);
			}
			$lb->see('end');
			$foo = '';
		    })->pack;
$f->Button(-text => 'Replace history',
	   -command => sub {
	       $b->history([keys %ENV]);
	   }
	  )->pack;
$b->bind('<Return>' => sub { $bb->invoke });

my $f2 = $top->Frame->grid(-row => 1, -column => 0, -sticky => 'n');
my $lb2 = $top->Scrolled('Listbox', -scrollbars => 'osoe'
			)->grid(-row => 1, -column => 1);
$f2->Label(-text => 'HistEntry with invoke, limit ...')->pack;
my $b2;
$b2 = $f2->HistEntry(-textvariable => \$bla,
		     -match => 1,
		     -label => 'Test label',
		     -labelPack => [-side => 'left'],
		     -width => 10,
		     -bell => 0,
		     -dup => 0,
		     -limit => 6,
		     -command => sub {
			 my $w = shift;
			 # automatic historyAdd
			 $lb2->delete(0, 'end');
			 foreach ($b2->history) {
			     $lb2->insert('end', $_);
			 }
			 $lb2->see('end');
		     })->pack;

#XXX$b2->configure(-match => 1);#XXX
$f2->Button(-text => 'Add current',
	    -command => sub { $b2->invoke })->pack;

my $f3 = $top->Frame->grid(-row => 2, -column => 0, -sticky => 'n');
my $lb3 = $top->Scrolled('Listbox', -scrollbars => 'osoe'
			)->grid(-row => 2, -column => 1);
$f3->Label(-text => 'SimpleHistEntry')->pack;
my $b3 = $f3->SimpleHistEntry(-textvariable => \$blubber,
			      -command => sub {
				  my($w, $line, $added) = @_;
				  if ($added) {
				      $lb3->insert('end', $line);
				      $lb3->see('end');
				  }
				  $blubber = '';
			      })->pack;
$f3->Button(-text => 'Add current',
	    -command => sub { $b3->invoke })->pack;

# # Autodestroy
# my $seconds = 60;
# my $autodestroy_text = "Autodestroy in " . $seconds . "s\n";
# $top->Label(-textvariable => \$autodestroy_text,
# 	   )->grid(-row => 99, -column => 0, -columnspan => 2);
# $top->repeat(1000, sub { if ($seconds <= 0) { $top->destroy }
# 			 $seconds--;
# 			 $autodestroy_text = "Autodestroy in " . $seconds
# 			   . "s\n";
# 		     });

$top->Button(-text => 'Exit',
	     -command => sub { $top->destroy },
	    )->grid(-row => 99, -column => 0, -columnspan => 2);

MainLoop;

