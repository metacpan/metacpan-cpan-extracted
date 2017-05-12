#!/usr/local/bin/perl5

use Tk::SlideShow;
use strict;

my $p = Tk::SlideShow->init(1024,768) or die;
$p->save;
my ($mw,$c,$h,$w) = ($p->mw, $p->canvas, $p->h, $p->w);
my $d;

sub sca {
  my ($id,$title,@mes) = @_;
  my $sp = $p->newSprite($id);
  $sp->pan(1);
  my $lval;
  my $chmes;
  my $sc;
  $chmes = sub {
    my $val = shift;
    goto fin unless defined $lval;
    $c->delete("text-$id");
    my $max = 10;
    for (0..$max) {
      my $lup = int(100*$_/$max);
      my $ldown = int(100*($max-$_)/$max);
      $c->delete('temp');
      $c->createText($sp->x,$sp->y,-text,$mes[$lval],
		     -anchor,'e', -font, $p->f2, -fill => "gray$lup", 
		     -justify,"center",
		     -tags => 'temp') if defined $lval;
      $c->createText($sp->x,$sp->y,-text,$mes[$val],
		     -justify,"center",
		     -anchor,'e', -font, $p->f2, -fill => "gray$ldown", 
		     -tags => 'temp');
      $c->update;
    }
    $c->delete('temp');
    $c->createText($sp->x,$sp->y,-text,$mes[$val],
		     -justify,"center",
		   -anchor,'e',
		   -font, $p->f2, -tags=> [$id,"text-$id"]);
  fin:
    $lval = $val;
  };
  $sc = $mw->Scale(-orient => 'horizontal',
		      -width=>100, -length => 300,
		      -from =>0,
		      -to => $#mes,
		      -command => $chmes,
		      -showvalue=>0);
  $sc->set(1);
  $c->createWindow($w/2,$h/2,-anchor,"w",
		   -window => $sc,
		   -tags => $id);
  $c->createText($w/2+350,$h/2,-text, $title, -font, $p->f2,
		 -anchor,'w',
		      -fill, 'red',
		     -tags => $id);
  
}
  
$d = $p->add('summary',
	     sub {
	       $p->Text('explain',
"Often, you have to show compromize
And the scale widget is a good tool for that ...
So let's use it ! Click on right button and
let the scales appears ... then look at the
code of this slide !",-font=> $p->f1);
	       sca('es1',"Laziness",
		   "message1","Bonjour","Au revoir");
	       sca('es2',"Impatience",
		   "message\nes2","Program","End","forth\nmessages");
	       sca('es3',"Hubris",
		   "Goodbye","Hello","ByeBye");
	       $p->load;
	       $p->a_left('es1','es2','es3');
	     });



#--------------------------------------------

$d->html(" ");

sub title { $p->Text('title',shift,-font,$p->f3); }


$p->current(shift || 0);
$p->play;
