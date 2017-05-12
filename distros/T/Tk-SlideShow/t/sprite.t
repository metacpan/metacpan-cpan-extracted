#!/usr/local/bin/perl5
# Date de création : Sat May 22 20:16:45 1999
# par : Olivier Bouteille (oli@localhost.oleane.com)


use Tk::SlideShow;
use strict;

chdir('t');
print "1..1\n";	
my $p = Tk::SlideShow->init(1024,768);
$p->save;
my ($mw,$c,$h,$w) = ($p->mw, $p->canvas, $p->h, $p->w);

sub compuman {
  my $s = $p->newSprite(shift);
  my $id = $s->id;
  my @o1 = (-width ,4,-fill, 'black', -tags ,$id);
  my @o2 = (-fill,'blue', -tags ,$id);
  my @o3 = (-width ,4,-fill,'red', -tags ,$id);
  $c->createLine(qw(10 20 10 40 25 40 25 50),@o1); #chair
  $c->createLine(qw(15 15 15 35 30 35 30 50 35 50),@o1); # body
  $c->createOval(qw(11 11 18 18),@o2); # head
  $c->createLine(qw(15 25 30 25),@o1); # feet
  $c->createLine(qw(30 27 40 22),@o3); # keyborad
  $c->createPolygon(qw(35 20 40 0 55 10 55 20),@o3); # ecran
  $c->createLine(qw(45 20 45 30 35 30 35 30),@o3); # 
  $s->pan(1);
  return $s;
}

$p->add('sprite', 
	sub { 
	  $p->Text('text','Text Sprite',-font,$p->f3);
	  $p->Image('image','Xcamel.gif');
	  $p->Image('i2','eq1.gif');
	  $p->newLink($p->Anim('anim','anim.gif'),
		      $p->Oval('oval',-width,4,-outline,'orange'));
	  $p->newArrow('text','i2');
	  for (1..10) {compuman("gus$_");}
	  $p->load ;
	  print "ok 1\n";
	});



$p->current($_[0] || 0);
if (@ARGV) {
  $p->play;
} else {
  $p->play(1);
}

# Local Variables: ***
# mode: perl ***
# End: ***






