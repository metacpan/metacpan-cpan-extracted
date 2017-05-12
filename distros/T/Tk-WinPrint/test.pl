#!/usr/local/bin/perl -w
# -*- perl -*-

#
# $Id: test.pl,v 1.1 2004/03/20 20:23:46 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 1999,2000 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

use Tk;
use Tk::WinPrint;

$top = new MainWindow;
$c = $top->Canvas->pack;
$c->createLine(10,20,30,100);
$c->createLine(210,120,230,100);
$c->createImage(100,100,-image => $top->Photo(-file => Tk->findINC("Xcamel.gif")));
$c->createWindow(200,200,-window => $c->Button(-text => "Print canvas",
					      -command => sub {
						  $c->print;
					      }));
$c->update;
MainLoop;
__END__
