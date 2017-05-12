
use Tk::SlideShow;
use strict;

chdir('t');
print "1..1\n";	
my $p = Tk::SlideShow->init(1024,768);
$p->save;
my ($mw,$c,$h,$w) = ($p->mw, $p->canvas, $p->h, $p->w);

$p->add('tape', 
	sub {
	  my $text = "Tk::SlideShow has no cause to be jealous of PowerPoint ......";
	  $p->TickerTape('m2', $text, 10, -font => $p->f2);
	  $p->TickerTape('m3', $text, 10, -font => $p->f3);
	  $p->TickerTape('m4', $text, 10, -font => $p->f4);
	  $p->TickerTape('m5', $text, 10, -font => $p->f5);
	  $p->TickerTape('m',"This may block your server a little bit. Type q to quit this test...", 20,-font, $p->f1);
	  $p->load;
	  print "ok 1\n";
	});

if (grep /^-abstract$/,@ARGV) {
  $p->latexabstract("abstract.tex");
  exit 0;
}

$p->current($ARGV[0] || 0);

if (@ARGV) {
  $p->play;
} else {
  print "PLaying just 5 second !\n";
  $p->play(5);
}
