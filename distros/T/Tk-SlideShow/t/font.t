#!/usr/local/bin/perl5
# Date de création : Sat May 22 20:16:45 1999
# par : Olivier Bouteille (oli@localhost.oleane.com)


use Tk::SlideShow;
use strict;

chdir('t');
my $p = Tk::SlideShow->init(1024,768);
$p->save;
my ($mw,$c,$h,$w) = ($p->mw, $p->canvas, $p->h, $p->w);
my $warning = "Warning : It may take some time 
	and block your X11 server
	for a while";

my %f;
open(FONT,"xlsfonts |") or die;
while(<FONT>) {
  next unless /^-/;
  my @a = split /-/;
  next unless $a[9] == 0;
  $f{$a[2]} = 1;
}

my @family = sort keys %f;


$p->add('size', 
	sub { 
	  $p->Text('warning',$warning,-font, $p->f2,-fill,'red');
	  $p->Text('advert',"This takes the whole screen size\nin case of a 1024x768 definition",
		   -font, $p->f1_5,-fill,'green');
	  for (qw(f0_5 f1 f1_5 f2 f3 f4 f5 ff0_5 ff1 ff2 ff3)) {
	    $p->Text($_,"text $_",-font, eval "\$p->$_");
	  }
	  $p->load ;
	  print "ok 1\n";
	});
my $counter = 1;
while (@family) {
  my @ft = splice(@family,0,5);
  
  {
    my $thistest = $counter+1;
    $p->add("family$counter", 
	    sub { 
	  print "$warning\n";
	  my $scounter = 0;
	  $p->family('times');
	  $p->Text('fontpos/warning',$warning,-font, $p->f2,-fill,'red');
	  for (@ft) {
	    print "Create text for font $_\n";
	    $p->family('utopia');
	    $p->Text("fontpos/t$scounter","$_    ",-font,$p->f1,-anchor,'e');
	    $p->family($_);
	    $p->Text("fontpos/t$scounter",'Bonjour ABab àéèùô',-font,$p->f3,-anchor,'w');
	    $scounter++;
	  }
	  $p->load("fontpos");
	  $p->family('utopia');
	  print "ok $thistest\n";
	});
  }
  $counter ++;
}
print "1..$counter\n";	

if (grep /^-abstract$/,@ARGV) {
  $p->latexabstract("abstract.tex");
  exit 0;
}
			      

$p->current($ARGV[0] || 0);
if (@ARGV) {
  $p->play;
} else {
  $p->play(1);
}

# Local Variables: ***
# mode: perl ***
# End: ***

