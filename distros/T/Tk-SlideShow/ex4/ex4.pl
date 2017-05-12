#!/usr/local/bin/perl5 -w
# Date de création : Mon May 24 15:35:58 1999
# par : Olivier Bouteille (oli@localhost.oleane.com)

use lib qw(../blib/lib);

use Tk::SlideShow;
use strict;

my $p = Tk::SlideShow->init(600,600);
$p->save;
$p->family('times');
$p->add('chooser', sub {
	  $p->Text('title',"The title",-font,$p->f5);
	  $p->Text('another',"Another text",-font,$p->f5);
	  $p->Text('test',"Default font",-font,$p->f5);
	  $p->load;
	});

$p->add('multipos', sub {
	  my $s = $p->Compuman('t');
	  for(1..10) {$p->Text("i$_","Text numéro $_");}
	  $p->load;
	  $p->a_multipos('t',10,-speed,2000,-steps,2);
	});

$p->current(shift || 0);
$p->play;


# Local Variables: ***
# mode: perl ***
# End: ***
