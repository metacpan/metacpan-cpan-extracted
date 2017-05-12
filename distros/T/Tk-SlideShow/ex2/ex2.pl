#!/usr/local/bin/perl5 -I../blib/lib -w

use Tk::SlideShow;
use vars qw($s);
use strict;

my $p=init Tk::SlideShow(1024,768) or die;


$p->save;

my ($mw,$c,$h,$w) = ($p->mw, $p->canvas, $p->h, $p->w);

sub car {
  my $id = shift;
  my $s = $p->newSprite($id);
  $mw->Photo('oli',-file => 'Xcamel.gif');
  $c->createPolygon
    (qw/0 50 25 50 35 35 140 35 160 50 200 50 200 75 0 75 0 50/,
     -fill, 'red', -tags, $id);
  $c->createOval(qw/20 85 40 65/,-fill, 'blue',-tags,$id);
  $c->createOval(qw/140 85 160 65/,-fill, 'blue',-tags,$id);
  $c->createImage(100,35,-image,'oli',-tags, $id, -anchor,'s');
  $c->move($id,$s->x,$s->y);
  $s->pan(2);
  $s->{'t'} = 0;
  sub deplace {
    my ($s,$id) = @_;
    $c->move($id,int(cos($s->{'t'})*2),int(sin($s->{'t'})*2));
    $s->{'t'} += 0.1;
    $c->after(100,[\&deplace,$s,$id] );
  }
  &deplace($s, $id);
  $s->pan(1);
  return $s;  
}

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


$p->bg (sub {
	  $c->configure(-background,'chocolate');
	  $c->createText($w,0,-text,"Olivier Bouteille",
			 -anchor => 'ne',
			 -font => $p->f1,
			 -fill => 'yellow');
	});

$p->add('demo', sub {
	   compuman('gus1');
	   car('v1');
	   car('v2');
	   $p->load;
	 }
);
$p->add('sharefont', sub {
	  my %f;
	  open(FONT,"xlsfonts |") or die;
	  while(<FONT>) {
	    next unless /sharefont/;
	    my @a = split /-/;
	    $f{$a[2]} = 1;
	  }
	  for (sort keys %f) {
	     print "Family $_\n";
	     $p->family('utopia');
	     $p->Text("t$_","$_    ",-font,$p->f1_5,-anchor,'e');
	     $p->family($_);
	     $p->Text("t$_",'Bonjour',-font,$p->f1_5,-anchor,'w');
	   }
	   $p->load;
	 }
);
$p->add('freefont', sub {
	  my %f;
	  open(FONT,"xlsfonts |") or die;
	  while(<FONT>) {
	    next unless /freefont/;
	    my @a = split /-/;
	    $f{$a[2]} = 1;
	  }
	   for (sort keys %f) {
	     print "Family $_\n";
	     $p->family('utopia');
	     $p->Text("t$_","$_    ",-font,$p->f1,-anchor,'e');
	     $p->family($_);
	     $p->Text("t$_",'Bonjour',-font,$p->f1,-anchor,'w');
	   }
	   $p->load;
	 }
);
$p->add('otherfont', sub {
	  my %f;
	  open(FONT,"xlsfonts |") or die;
	  while(<FONT>) {
	    next if /freefont/ or /sharefont/;
	    next unless /^-/;
	    my @a = split /-/;
	    print;
	    $f{$a[2]} = 1;
	  }
	   for (sort keys %f) {
	     print "Family $_\n";
	     $p->family('utopia');
	     $p->Text("t$_","$_    ",-font,$p->f1,-anchor,'e');
	     $p->family($_);
	     $p->Text("t$_",'Bonjour',-font,$p->f2,-anchor,'w');
	   }
	   $p->load;
	 }
);


$p->current(shift || 0);
$p->play;


