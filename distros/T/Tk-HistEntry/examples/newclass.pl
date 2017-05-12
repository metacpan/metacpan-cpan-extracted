#!/usr/local/bin/perl -w
# -*- perl -*-

#
# $Id: newclass.pl,v 1.2 1998/05/20 08:38:12 eserte Exp $
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
use Tk::FireButton;
use strict;

package MyHistEntry;
@MyHistEntry::ISA = qw(Tk::Frame);
Construct Tk::Widget 'MyHistEntry';

{ my $foo = $Tk::FireButton::INCBITMAP;
     $foo = $Tk::FireButton::DECBITMAP; }

sub Populate {
    my($f, $args) = @_;

    my $e = $f->Component(SimpleHistEntry => 'entry');
    my $binc = $f->Component( FireButton => 'inc',
        -bitmap             => $Tk::FireButton::INCBITMAP,
        -command            => sub { $e->historyUp },
    );

    my $bdec = $f->Component( FireButton => 'dec',
        -bitmap             => $Tk::FireButton::DECBITMAP,
        -command            => sub { $e->historyDown },
    );

    $f->gridColumnconfigure(0, -weight => 1);
    $f->gridColumnconfigure(1, -weight => 0);

    $f->gridRowconfigure(0, -weight => 1);
    $f->gridRowconfigure(1, -weight => 1);

    $binc->grid(-row => 0, -column => 1, -sticky => 'news');
    $bdec->grid(-row => 1, -column => 1, -sticky => 'news');

    $e->grid(-row => 0, -column => 0, -rowspan => 2, -sticky => 'news');

    $f->ConfigSpecs
      (-repeatinterval => ['CHILDREN', "repeatInterval",
			   "RepeatInterval", 100       ],
       -repeatdelay    => ['CHILDREN', "repeatDelay",
			   "RepeatDeleay",   300       ],
       DEFAULT => [$e],
      );

    $f->Delegates(DEFAULT => $e);

    $f;

}

package main;

my $top = new MainWindow;

my($bla);

my($b2, $lb2);
$b2 = $top->MyHistEntry(-textvariable => \$bla,
			-repeatinterval => 30,
			-bell => 1,
			-dup => 1,
			-command => sub {
			    my($w, $s, $added) = @_;
			    if ($added) {
				$lb2->insert('end', $s);
				$lb2->see('end');
			    }
			    $bla = '';
			})->pack;
$lb2 = $top->Scrolled('Listbox', -scrollbars => 'osoe'
		     )->pack;

# # Autodestroy
# my $seconds = 60;
# my $autodestroy_text = "Autodestroy in " . $seconds . "s\n";
# $top->Label(-textvariable => \$autodestroy_text,
# 	   )->pack;
# $top->repeat(1000, sub { if ($seconds <= 0) { $top->destroy }
# 			 $seconds--;
# 			 $autodestroy_text = "Autodestroy in " . $seconds
# 			   . "s\n";
# 		     });

$top->Button(-text => 'Exit',
	     -command => sub { $top->destroy },
	    )->pack;

MainLoop;

