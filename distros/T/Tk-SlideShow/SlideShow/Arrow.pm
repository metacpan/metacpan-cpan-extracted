package Tk::SlideShow::Arrow;
@Tk::SlideShow::Arrow::ISA = qw(Tk::SlideShow::Link);
use strict;

sub New {
  my $class = shift;
  my $s = $class->SUPER::New(@_);
  bless $s;
  $s->{'shape'}=[8,10,3];
  $s->{'width'} = 1;

  my $id = $s->id;
  $s->initbind;
  $s->{-arrowoptions} = ['-arrow','last', '-width', $s->width, '-arrowshape', $s->shape];
  $s->trace_link(-100,-100,-10,-10);
  return $s;
}

sub initbind {
  my $s = shift;
  my $id = $s->id;
  my $c = Tk::SlideShow->canvas;
  
  $c->bind($id,"<ButtonPress-2>", 
	   sub { 
	       my $e = (shift)->XEvent;
	       $c->raise($id);
	       print "B2 \n";
	       $c->configure(-cursor,'sizing');
	       ($s->{'sx'},$s->{'sy'}) = ($c->canvasx($e->x),$c->canvasy($e->y));
	     });
  $c->bind($id,"<B2-Motion>", 
	   sub {
	     my $e = (shift)->XEvent;
	     my ($nx,$ny) = ($c->canvasx($e->x),$c->canvasy($e->y));
	     my ($dx,$dy) = ($nx - $s->{'sx'}, $ny - $s->{'sy'});
	     if ($dx == 0) {
	       $s->{'width'} -= $dy > 0 ? 1 : - 1;
	       $s->{'width'} = abs($s->{'width'});
	     } elsif (($dx > 0 or $dy > 0) and ($dx*$dy < 0 )) {
	       $s->{'shape'}[0] += $dx > 0 ? 1 : - 1;
	       $s->{'shape'}[0] = abs($s->{'shape'}[0]);
	     } elsif ( $dy == 0 ) {
	       $s->{'shape'}[1] += $dx > 0 ? 1 : - 1;
	       $s->{'shape'}[1] = abs($s->{'shape'}[1]);
	     } elsif ($dx*$dy > 0) {
	       $s->{'shape'}[2] += $dx > 0 ? 1 : - 1;
	       $s->{'shape'}[2] = abs($s->{'shape'}[2]);
	     } else {
	       print "*** anormal\n";
	     }

	     ($s->{'sx'}, $s->{'sy'}) = ($nx,$ny);
	     $c->itemconfigure($s->{'lineid'},'-width',$s->{'width'});
	     $c->itemconfigure($s->{'lineid'},'-arrowshape', $s->shape);
	   });

}

sub evalplace {
  my $s = shift;
  return sprintf("ftpos(%d,%d)->width(%d)->shape(%d,%d,%d)",
		 $s->fpos,$s->tpos,$s->width,@{$s->shape});
}

sub shape {
  my ($s,@vals) = @_;
  if (scalar(@vals>0) and @vals == 3) {
    $s->{'shape'} = [@vals];
    Tk::SlideShow->canvas->itemconfigure($s->{'lineid'},'-arrowshape', [@vals] );
    return $s;
  }
  return $s->{'shape'};
}
sub width {
  my ($s,$val) = @_;
  if (defined $val) {
    $s->{'width'} = $val;
    Tk::SlideShow->canvas->itemconfigure($s->{'lineid'},'-width',$val);
    return $s;
  }
  return $s->{'width'};
}

1;
