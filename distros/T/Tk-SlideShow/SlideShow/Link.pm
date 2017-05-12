
use strict;

package Tk::SlideShow::Link;

@Tk::SlideShow::Link::ISA = qw(Tk::SlideShow::Placeable);

sub New {
  my ($class,$from,$to,$titre,@options) = @_;

  $from = Tk::SlideShow::Dict->Get($from) or die unless ref($from);
#  print "from =$from\n";
  $to = Tk::SlideShow::Sprite->point($from->id."-to") unless $to;

  $to = Tk::SlideShow::Dict->Get($to) or die unless ref($to);

  my $id = sprintf("%s-%s",$from->id,$to->id);
  my $s =  bless {'from'=>$from, 'to'=>$to, 'id'=> $id, 'titre' => $titre || "",
		 'tpos' => 0, 'fpos' => 0, -options => [], -arrowoptions => []};
  if (@options>0) {$s->{-options} = [@options]};
  
  $class->Set($id,$s);
  $from->addLink($s);
  $to->addLink($s);
  $s->show;
  $s->bind;
  $s->trace_link(-100,-100,0,0);
  $s->cursor('hand1');
  return $s;
}

sub bind {
  my $s = shift;
  my $c = Tk::SlideShow->canvas ;
  my $id = $s->id;
  my $movepos = sub {
    my $e = (shift)->XEvent;
    my ($id,$incr) = @_;
    $c->raise($id);
    my ($x,$y) = ($c->canvasx($e->x),$c->canvasy($e->y));
    if ((abs($s->fx - $x)+abs($s->fy-$y)) >
	(abs($s->tx - $x)+abs($s->ty-$y))) {
      $s->{'tpos'} += $incr;
      my ($x,$y) = $s->to->pos($s->tpos);
      Tk::SlideShow::warppointer($x,$y);
    } else {
      $s->{'fpos'} += $incr;
      my ($x,$y) = $s->from->pos($s->fpos);
      Tk::SlideShow::warppointer($x,$y);
    }
    $s->show;
  };
  $c->bind($id,"<1>", [$movepos, $id, 1]);
  $c->bind($id,"<3>", [$movepos, $id,-1]);

}
sub from { return (shift)->{'from'} }
sub to { return (shift)->{'to'} }
sub titre { return (shift)->{'titre'} }
sub id { return (shift)->{'id'} }
sub fpos { return (shift)->var_getset('fpos',(shift))}
sub tpos { return (shift)->var_getset('tpos',(shift))}
sub ftpos {
  my ($s,$f,$t) = @_;
  $s->{'fpos'}=$f;
  $s->{'tpos'}=$t;
  $s->show;
  return $s;
}
sub fx { return (shift)->{'fx'} }
sub fy { return (shift)->{'fy'} }
sub tx { return (shift)->{'tx'} }
sub ty { return (shift)->{'ty'} }

sub show {
  my $s = shift;

  my $from = $s->from;
  my $to = $s->to;

  my $can = Tk::SlideShow->canvas;
  my ($w,$h) = (Tk::SlideShow->w,Tk::SlideShow->h);
  my $id = $s->id;
  
  my $fpos = $s->fpos % 8;
  my ($fx,$fy) = $from->pos($fpos);
  $s->{'fpos'} = $fpos;
  $s->{'fx'} = $fx;
  $s->{'fy'} = $fy;

  my $tpos = $s->tpos % 8;
  my ($tx,$ty) = $to->pos($tpos);
  $s->{'tpos'} =$tpos;
  $s->{'tx'} = $tx;
  $s->{'ty'} = $ty;

  return   if $fx < 0 or $fx > $w or $fy < 0 or $fy > $h;
  return   if $tx < 0 or $tx > $w or $ty < 0 or $ty > $h;
#  print "redraw ($fx,$fy,$tx,$ty) (fpos=$fpos,tpos=$tpos)\n";
  $s->redraw($fx,$fy,$tx,$ty);

  return $s;
}

sub trace_link {
  my ($s,$fx,$fy,$tx,$ty) = @_;
  my $id = $s->id;
  my $can =  Tk::SlideShow->canvas;
  $can->delete($s->id);
  $s->{'lineid'} = $can->createLine($fx,$fy,$tx,$ty,-tags,$id,
				   @{$s->{-arrowoptions}},
				    @{$s->{-options}},
				   );
#  print "Arrow Option of ".ref($s)."($id) = ".join(',',@{$s->{-arrowoptions}})."\n";
  if ($s->titre) {
    my $wid = $can->createText(($fx+$tx)/2,($fy+$ty)/2,'-text',$s->titre, -tags,$id);
    my $rectid = $can->createRectangle($can->bbox($wid),-fill,'lightYellow',-outline,'red',-tags,$id);
    $can->raise($wid);
    $s->{'titleid'} = $wid;
    $s->{'rectid'} = $rectid;
  }
}

sub redraw {
  my ($s,$fx,$fy,$tx,$ty) = @_;
  my $id = $s->id;
  my $c =  Tk::SlideShow->canvas;
  my $lineid = $s->{'lineid'};
  $c->coords($lineid,$fx,$fy,$tx,$ty);
  if ($s->titre) {
    my $wid = $s->{'titleid'};
    $c->coords($wid,($fx+$tx)/2,($fy+$ty)/2);
    $c->coords($s->{'rectid'},$c->bbox($wid));
  }
}


sub hide {(shift)->redraw(-100,-100,-10,-10);}

sub evalplace {
  my $s = shift;
  return sprintf("ftpos(%d,%d)",$s->fpos,$s->tpos);
}

1;
