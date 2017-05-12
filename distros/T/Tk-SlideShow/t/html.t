
use Tk::SlideShow;
use strict;

chdir('t');
print "1..1\n";	
my $p = Tk::SlideShow->init(1024,768);
$p->save;
my ($mw,$c,$h,$w) = ($p->mw, $p->canvas, $p->h, $p->w);

my $d = $p->add('html', 
	sub {
	  $p->Text('doc',"Html doc\nadding/producing\nis possible",
		  -font, $p->f3);
	  $p->Text('smile',"Smile please, I'm just snapshot'ing your slides ...",
		  -font, $p->f1);
	  $p->load;
	});

$d->html('<H1> html doc is possible </h1>');

$p->html("doc");
print "ok 1\n";

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
