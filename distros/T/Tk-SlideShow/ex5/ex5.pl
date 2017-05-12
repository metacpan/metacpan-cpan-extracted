#!/usr/local/bin/perl5

use Tk::SlideShow;
use strict;

my $p = Tk::SlideShow->init(1024,768) or die;

$p->save;

my ($mw,$c,$h,$w) = ($p->mw, $p->canvas, $p->h, $p->w);
my $d;

#--------------------------------------------
sub trace_syn {
  my @t = qw(fourn   Fournisseurs 
	     in      Entrée 
	     trait   Traitements 
	     post    Post-Trait 
	     out     Sortie 
	     client  Clients);
  my $last;
  while(@t) {
    my ($k,$v) = (shift @t, shift @t);
    boite("syn/$k",$v);  $p->warp("syn/$k",'<Double-1>', $k);
    $p->newArrow("syn/$last","syn/$k") if defined $last;
    $last = $k;
  }
  $p->load('syn');
}  

$d = $p->add('summary',
	     sub {
	       title('First title');
	       &trace_syn;
	       $p->load;
	       $p->a_left(qw(syn/fourn syn/in syn/trait syn/post syn/out syn/client));
	     });
$d = $p->add('synopsys',
	     sub {
	       title('Synopsys');
	       &trace_syn;
	       compuman('gus');
	       $p->load;
	       $p->a_multipos('gus',5);
	     });

$d->html(" ");

$d = $p->add('fourn',
	     sub {
	       title('Les Fournisseurs');
	       boite('retour',"Retour"); $p->warp('retour','<Double-1>', 'synopsys');
	       $p->load;
	     }
	    );
#--------------------------------------------

sub title { $p->Text('title',shift,-font,$p->f3); }

sub items {
  my ($id,$items,@options) = @_; my @ids;
  for (split (/\n/,$items)) {
    s/^\s*//; s/\s*$//;
    $p->Text($id,$_,@options);
    push @ids,$id; $id++;
  }
  return @ids;
}

sub boite {
  my ($id,$t,@options) = @_;
  $t =~ s/^\s+//; $t =~ s/\s+$//;
  my $s = $p->newSprite($id);
  my $f = $c->Font('family'  => "courier", point => 250, -weight => 'bold');
  my $idw = $c->createText(0,0,-text,$t,@options, -tags => $id,
			   -fill,'yellow', -font => $f,
			  -anchor => 'nw');
  $c->createRectangle($c->bbox($idw), -fill,'black',-tags => $id);
  $c->raise($idw);
  $s->pan(1);
  return $s;
}


if (grep (/-html/,@ARGV)) {
  $p->html("doc");
  exit 0;
}

$p->current(shift || 0);
$p->play;



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
  $c->move($id,$h/2,$w/2);
  $s->pan(1);
  return $s;
}
