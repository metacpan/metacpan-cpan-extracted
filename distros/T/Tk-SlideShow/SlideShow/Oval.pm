
use strict;

package Tk::SlideShow::Oval;

@Tk::SlideShow::Oval::ISA = qw(Tk::SlideShow::Sprite);


my $chheight  = sub {
  my ($c,$s,$incr) = @_;
  print "chheight\n";
  $s->{'height'} += $incr;
  $s->show;
};

my $chwidth  = sub {
  my ($c,$s,$incr) = @_;
  $s->{'width'} += $incr;
  print "chwidth\n";
  $s->show;
};

sub New {
  my ($class,$id,@options) = @_;
  my $s = Tk::SlideShow::Sprite->New($id);
  
  my ($h,$w) = (Tk::SlideShow->h,Tk::SlideShow->w);
  $s->{'width'} = 200;
  $s->{'height'} = 200;
  $s->{'options'} = [@options];
  my $x = $s->{'x'} = $w/2;
  my $y = $s->{'y'} = $h/2;
  bless $s;
  $s->pan(1);
  $s->initbind;
  my $c = Tk::SlideShow->canvas;
  $c->createOval
    ($x-int($w/2), $y-int($h/2), $x+int($w/2), $y+int($h/2),
     -tags,$s->id, @{$s->{'options'}});
  $s->show;
  $s->cursor('target');
  return $s;
}
sub show { 
  my $s = shift;
  my $c = Tk::SlideShow->canvas;
  my ($x,$y,$w,$h) = ($s->xy,$s->wh);
  $c->coords($s->id,$x-int($w/2), $y-int($h/2), $x+int($w/2), $y+int($h/2));
  for my $l ($s->links) {$l->show;}

}

sub evalplace {
  my $s = shift;
  my $ret = Tk::SlideShow::Sprite::evalplace($s);

  $ret .= sprintf("->wh(%d,%d)",$s->{'width'},$s->{'height'});
  return $ret;
}

sub wh {
  my ($s,$w,$h) = @_;
  
  return ($s->{'width'},$s->{'height'}) unless defined $w;
  
  $s->{'width'}= $w;
  $s->{'height'}=$h;

  $s->show;
  return $s;
}
sub initbind {
  my $s = shift;
  my $c = Tk::SlideShow->canvas;
  my $id = $s->id;
  $c->bind($id,"<ButtonPress-2>", 
	   sub { 
	       my $e = (shift)->XEvent;
	       $c->raise($id);
#	       print "B2 \n";
	       $c->configure(-cursor,'sizing');
	       ($s->{'swx'},$s->{'shy'}) = ($c->canvasx($e->x),$c->canvasy($e->y));
	     });
  $c->bind($id,"<B2-Motion>", 
	   sub {
#	     print "B2-Motion \n";
	     my $e = (shift)->XEvent;
	     my ($nx,$ny) = ($c->canvasx($e->x),$c->canvasy($e->y));
	     my ($dw,$dh) = ($nx - $s->{'swx'}, $ny - $s->{'shy'});
#	     print "delta $dw, $dh ($id)\n";
	     ($s->{'swx'}, $s->{'shy'}) = ($nx,$ny);
	     $s->{'height'} += $dh;
	     $s->{'width'}  += $dw;
	     my ($x,$y,$w,$h) = ($s->xy,$s->wh);
	     $c->coords($s->id,$x-int($w/2), $y-int($h/2), $x+int($w/2), $y+int($h/2));
	   });
  $c->bind($id,"<ButtonRelease-2>",
	   sub {
	     $s->show;
	     $c->configure(-cursor,'top_left_arrow');
	     });
}

1;

