#!/usr/local/bin/perl5 -I.. -w

use SlideShow;
use strict;
	
my $p = Tk::SlideShow->init(1024,768) or die;
$p->save;
my ($mw,$c,$h,$w) = ($p->mw, $p->can, $p->h, $p->w);

$p->add('tapesmooth', sub {
	  my $text = "Tk::SlideShow has no cause to be jealous of PowerPoint ......";
	  $p->TickerTape('m2', $text, 10, -font => $p->f2);
	  $p->TickerTape('m3', $text, 10, -font => $p->f3);
	  $p->TickerTape('m4', $text, 10, -font => $p->f4);
	  $p->TickerTape('m5', $text, 10, -font => $p->f5);
	  $p->TickerTape('m',"This may block your server a little bit ", 20,-font, $p->f1);
	  $p->load });

$p->current(shift || 0);
$p->play;

