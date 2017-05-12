#!/usr/local/bin/perl -w
# -*- perl -*-

#
# $Id: autoscroll.pl,v 1.8 2003/10/22 21:06:19 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 1999,2002 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

use Tk;
use Tk::Autoscroll qw(as_default);
@Tk::Autoscroll::default_args = (-stoptrigger => '<ButtonRelease-2>');

$top = new MainWindow;

$top->Label(-text => "Hold middle button to en/disable scrolling")->pack;

$lb = $top->Scrolled('Listbox')->pack;
$lb->insert("end", 1..1000);

$c = $top->Scrolled('Canvas')->pack;
for(1..1000) {
    my($x1,$y1,$x2,$y2) = (int(rand(500)), int(rand(500)),
			   int(rand(500)), int(rand(500)));
    $c->createLine($x1,$y1,$x2,$y2, -fill => "red");
}

# XXX Problem: widgets inside the scrolled widget steal the
# events ...
eval q{
    use Tk::Pane;
    $p = $top->Scrolled('Pane')->pack;
    for (1..10) {
	$f[$_] = $p->Frame->pack;
    }
    for (1..10) {
	for my $y (1..5) {
	    $f[$_]->Label(-text => "$_/$y")->pack;
	}
    }
};
warn $@ if $@;

if (!$ENV{BATCH}) {
    MainLoop;
}

__END__
