#!/usr/local/bin/perl5
# Date de création : Thu Dec 24 06:56:38 1998
# par : Olivier Bouteille (oli@localhost.oleane.com)

use Tk;

$m = new MainWindow;

$c = $m->Canvas->pack;

$c->Tk::bind('<1>', sub {print "coucou\n";});

$b = $m->Button(-text,'press',-command =>
		sub {
		  $m->eventGenerate('<Motion>','-x',20,'-y',20);})->pack;

MainLoop;

# Local Variables: ***
# mode: perl ***
# End: ***
