package Tk::SlideShow::Sprite;
use strict;
use vars qw(@ISA); @ISA = qw(Tk::SlideShow::Placeable);

sub New {
  my ($class,$id) = @_;
  my $s = $class->SUPER::New($id);
  $s->{'link'}= [];
  bless $s;
  return $s;
}

sub null {
  my ($class) = @_;
  my $s = $class->SUPER::New('__null__');
  bless $s;
  return $s;
}

sub evalplace {
  my $s = shift;
  my $ret = "";
  if (exists $s->{'multipos'}) {
    $s->{'multipos'}[$s->{'curposindex'}] = [$s->x,$s->y];
    $ret .= "multipos(". join(',',map {join(',',@$_)} @{$s->{'multipos'}}). ")";
  } else {
    $ret .= sprintf("place(%d,%d)",$s->x,$s->y);
  }
  $ret .= sprintf("->fontFamily('%s')",$s->fontFamily) 
    if exists $s->{'-font'} && $s->{'-font'};
  $ret .= sprintf("->color('%s')",$s->color) 
    if exists $s->{'-color'} && $s->{'-color'};
  return $ret;
}


sub place {
  my ($s,$x,$y) = @_;
  my ($dx,$dy) = ($x-$s->x,$y-$s->y);
  Tk::SlideShow->canvas->move($s->id,$dx,$dy);
  $s->{'x'} = $x;
  $s->{'y'} = $y;
  return $s;
}

sub multipos {
  my ($s,@xy) = @_;
  my $i = 0;
  while(@xy) {$s->{'multipos'}[$i] = [splice(@xy,0,2)]; $i++}
  $s->place(@{$s->{'multipos'}[0]});
}

sub chpos {
  my ($s,$i,%options) = @_;
  my $tag = $s->{'id'};
  my $lasti;
  $s->{'multipos'} = [] unless exists $s->{'multipos'};

  my $can = Tk::SlideShow->canvas;
  my ($H,$W) = (Tk::SlideShow->h,Tk::SlideShow->w);
  if (exists $s->{'curposindex'}) {
    $lasti = $s->{'curposindex'};
  } else {
    $lasti = 0;
  }
  #print "Saving pos $lasti for $tag\n";
  my ($x,$y) = ($s->x,$s->y);
  $s->{'multipos'}[$lasti] = [$x,$y];

  #print "moving tag $tag to position $i\n";
  $s->{'multipos'}[$i] = [$H/2,$W/2] 
    unless defined $s->{'multipos'}[$i];
  my ($destx,$desty) = @{$s->{'multipos'}[$i]};
  # number of pixel per second
  my $speed = $options{'-speed'} || 1000;
  my $distance = (($destx-$x)**2+($desty-$y)**2)**.5;
#  printf ("deplacement de %d,%d a $destx,$desty\n",$x,$y);
  my $steps = $options{'-steps'} || 5;
  my $step = int($distance/$steps);
  my $dt = $distance / $speed;
#  print "dt=$dt  distance=$distance step=$step\n";
  my ($x0,$y0) = ($x,$y);
  my $dx = ($destx-$x0)/$step;
  my $dy = ($desty-$y0)/$step;
  sub smallmove {
    my ($can,$tag,$t,$step,$x0,$y0,$x,$y,$dx,$dy,$dt) = @_;
    my $tx = $x0+$t*$dx;
    my $ty = $y0+$t*$dy;
    my ($tdx,$tdy)  = (int($tx-$x),int($ty-$y));
    $can->move($tag,$tdx,$tdy);
    my $spri = Tk::SlideShow::Dict->Get($tag);
    for my $l ($spri->links) {$l->show;}
    $x += $tdx; $y += $tdy;
    $can->update;
    $can->after(int($dt/$step*1000),
		[\&smallmove,$can,$tag,$t+1,$step,$x0,$y0,$x,$y,$dx,$dy,$dt])
      if $t <= $step ;
  }
  smallmove($can,$tag,1,$step,$x0,$y0,$x,$y,$dx,$dy,$dt);
  ($s->{'x'},$s->{'y'}) = ($destx, $desty);
  $s->{'curposindex'} = $i;
}

sub text {
  shift;
  my $id = shift;
  my $text = shift;
  my $s = New('Tk::SlideShow::Sprite',$id);
  my $c = Tk::SlideShow->canvas;
  my $item = 
    $c->createText
      (Tk::SlideShow->w/2,Tk::SlideShow->h/ 2,'-text', $text,
       -font, Tk::SlideShow->f1, -tags,$id);
  $c->itemconfigure($item,@_);
  $s->{-font} = "";   bindfontchoosermenu($id);
  $s->{-color} = ""; bindcolorchoosermenu($id);
  $s->pan(1);
  $s->cursor('umbrella');
  return $s;
}


# managing font for Sprites with text
{
  my (%f,@f);
  my $fontmenu; my $lbox;
  my ($curit, $cursp);
  sub initFontChooser {
    Tk::SlideShow->addkeyhelp('Double-Click Button 1 on text items',
			      'to access font chooser');
    my $can = Tk::SlideShow->canvas;
    my $mw = Tk::SlideShow->mw;
    open(FONT,"xlsfonts |") or die;
    while(<FONT>) {next unless /^-/; 
	my @a = split /-/; 
	# avoiding non scalable fonts
	next unless $a[9] == 0;
	$f{$a[2]} = 1;}
    close (FONT);
    $fontmenu = $mw->Menu;
    my $lb = $fontmenu->Scrolled('Listbox')->pack;
    $lbox = $lb->Subwidget('listbox');
    $lbox->bind('<Double-1>',
		sub {
		  my $fontindex = $lbox->curselection;
		  if (defined $curit and defined $cursp) {
		    my $font = $can->itemcget($curit,-font);
		    $font->configure('-family',$f[$fontindex]);
		    $cursp->{-font} = $f[$fontindex];
		  }
		  #print "item = $curit\n";
		  $fontmenu->unpost;
		  $curit =$cursp = undef;
		});
    @f = sort keys %f;
    $lb->insert('end',@f);
  }
  sub bindfontchoosermenu {
    my $tagorid = shift;
    my $c = Tk::SlideShow->canvas;
    $c->bind($tagorid,'<Double-1>',
	     sub {
	       my $e = (shift)->XEvent;
	       $curit = Tk::SlideShow->current_item;
	       $cursp = Tk::SlideShow::Sprite->Get($curit) 
		 if defined $curit;
	       $fontmenu->post($e->X,$e->Y);
	       }
	    );
  }
  sub fontFamily {
    my ($s,$fam) = @_;
    my $can = Tk::SlideShow->canvas;
    return $s->{-font} unless defined $fam;
    $s->{-font} = $fam;
    my $font = $can->itemcget($s->{'id'},-font);
    $font->configure('-family',$fam);
    return $s;
  }
}
# managing color for Sprites with color
{
  my (%color,@color);
  my $colormenu; my $lbox;
  my ($curit, $cursp);

  sub initColorChooser {
    Tk::SlideShow->addkeyhelp('Double-Click Button 3 on canvas items',
			      'to access color chooser');
    my $can = Tk::SlideShow->canvas;
    my $mw = Tk::SlideShow->mw;
    $colormenu = $mw->Menu;
    @color = qw(red green blue yellow black purple magenta);
    my $lb = $colormenu->Scrolled('Listbox')->pack;
    $lbox = $lb->Subwidget('listbox');
    $lb->insert('end',@color);
    $lbox->bind('<Double-1>',
		sub {
		  my $colorindex = $lbox->curselection;
		  if (defined $curit and defined $cursp) {
		    $can->itemconfigure($curit,-fill,$color[$colorindex]);
		    #print "on passe a la couleur=$colorindex :".$color[$colorindex]."\n";
		    $cursp->{-color} = $color[$colorindex] ;
		  }
		  #print "item = $curit\n";
		  $colormenu->unpost;
		  $curit =$cursp = undef;
		});
  }
  sub bindcolorchoosermenu {
    my $tagorid = shift;
    my $c = Tk::SlideShow->canvas;
    $c->bind($tagorid,'<Double-2>',
	     sub {
	       my $e = (shift)->XEvent;
	       $curit = Tk::SlideShow->current_item;
	       $cursp = Tk::SlideShow::Sprite->Get($curit) 
		 if defined $curit;
	       $colormenu->post($e->X,$e->Y);
	       }
	    );
  }
  sub color {
    my ($s,$col) = @_;
    my $can = Tk::SlideShow->canvas;
    return $s->{-color} unless defined $col;
    $s->{-color} = $col;
    $can->itemconfigure($s->{'id'},-fill,$col);
    #print "on met $s->{'id'} en $col\n";
    return $s;
  }
}

sub point {
  shift; my $id = shift;
  my $s = Tk::SlideShow::Sprite->New($id);
  my $c = Tk::SlideShow->canvas;
  my $item = 
    $c->createOval(qw(0 0 5 5),-fill,'blue', -tags ,$id);
  $s->pan(1);
  return $s;
}


sub anim {
  shift;
  my $id = shift;
  my $fn;
  if (not -e $id) {
    $fn = shift;
    die "je ne trouve pas $fn\n" unless -e $fn;
  } else { $fn = $id;}
  my $s = Tk::SlideShow::Sprite->New($id);
  $s->{'state'} = shift || 1;
  my $freq = shift || 200;
  my $c = Tk::SlideShow->canvas;
  my $mw = Tk::SlideShow->mw;
  my $im = $mw->Animation('-format' => 'gif',-file => $fn);
  $im->start_animation($freq) if $s->{'state'};
  Tk::SlideShow->addkeyhelp('Click Button 3 on animated gif',
			      'to toggle animation');

  $c->bind($id,'<3>',
	   [ sub { 
	       my ($c,$s,$im) = @_;
	       if ($s->{'state'}) {
		 #print "stopping ".$s->id."\n";
		 $im->stop_animation;
	       } else {
		 #print "starting ".$s->id."\n";
		 $im->start_animation($freq); 
	       }
	       $s->{'state'} =  1 - $s->{'state'};
	     },$s,$im]);
  $c->createImage(Tk::SlideShow->w/2,Tk::SlideShow->h/2,-image, $im, -tags,$id, @_);
  $s->pan(1);
  return $s;
}
sub image {
  shift;
  my $id = shift;
  my $s = Tk::SlideShow::Sprite->New($id);
  my $c = Tk::SlideShow->canvas;
  my $mw = Tk::SlideShow->mw;
  my $fn;
  if (not -e $id) {
    $fn = shift;
  } else {
    $fn = $id;
  }
  $mw->Photo($id,-file => $fn);
  $c->createImage(Tk::SlideShow->w/2,Tk::SlideShow->h/2,-image, $id, -tags,$id, @_);
  $s->pan(1);
  return $s;
}

sub window {
  shift;
  my $id = shift;
  my $s = Tk::SlideShow::Sprite->New($id);
  my $c = Tk::SlideShow->canvas;
  my $mw = Tk::SlideShow->mw;
  my $window = shift;

  $c->createWindow(Tk::SlideShow->w/2, Tk::SlideShow->h/2,
		   -window, $window, -tags,$id, @_);
  #printf("%s %s window\n",Tk::SlideShow->w/2, Tk::SlideShow->h/2);
  $s->pan(3);
  return $s;
}

sub hommeord {
  shift; # on supprime la classe
  my $s = Tk::SlideShow::Sprite->New(@_);
  my $c = Tk::SlideShow->canvas;
  my $id = $s->id;
  $c->createLine(qw(10 20 10 40 25 40 25 50),-width ,4,-fill, 'black', -tags ,$id); #chaise
  $c->createLine(qw(15 15 15 35 30 35 30 50 35 50),-width ,4,-fill,'blue', -tags ,$id);# corps 
  $c->createOval(qw(11 11 18 18),-fill,'blue', -tags ,$id);# tete
  $c->createLine(qw(15 25 30 25),-width ,4,-fill,'blue', -tags ,$id);# pieds
  $c->createLine(qw(30 27 40 22),-width ,4,-fill,'red', -tags ,$id);# clavier
  $c->createPolygon(qw(35 20 40 0 55 10 55 20),-width ,2,-fill,'red', -tags ,$id); # ecran
  $c->createLine(qw(45 20 45 30 35 30 35 30),-width ,2, -fill,'red', -tags ,$id);# support d'ecran
  $s->pan(1);
  return $s;  
}

sub moteur {
  shift;
  my $s = Tk::SlideShow::Sprite->New(@_);
  my $c = Tk::SlideShow->canvas;
  my $id = $s->id;

  $c->createOval(qw(0 0 50 50),-fill,'blue', -tags ,$id);
  $c->createText(qw(0 0),'-text',$id,-anchor,'e',-tags ,$id);
  my @ids;
  my @colors = qw(red blue);
  push @ids, $c->createLine(qw(10 10 40 40),-width ,10,-fill, 'red', -tags ,$id);
  push @ids, $c->createLine(qw(25 0 25 50),-width ,10,-fill, 'blue', -tags ,$id);
  push @ids, $c->createLine(qw(10 40 40 10),-width ,10,-fill, 'blue', -tags ,$id);
  push @ids, $c->createLine(qw(0 25 50 25),-width ,10,-fill, 'blue', -tags ,$id);
  $c->raise($ids[0]);
  $s->{'ids'} = [@ids];
  $s->{'toggle'} = 1;
  sub toggle {
    my $s = shift;
    my $c = Tk::SlideShow->canvas;
    $s->{'r'}->cancel if exists $s->{'r'};
    $c->itemconfigure ($s->{'ids'}[$s->{'toggle'}],-fill, 'blue');
    $s->{'toggle'}++; $s->{'toggle'} %= @{$s->{'ids'}};
    $c->itemconfigure ($s->{'ids'}[$s->{'toggle'}],-fill, 'red');
    $c->raise($s->{'ids'}[$s->{'toggle'}]);
    $s->{'r'} = $c->after(100,[\&toggle,$s]);
  }
  $c->bind($id,'<3>',
	   sub {
	     if (exists $s->{'r'}) {
	       $s->{'r'}->cancel;
	       delete $s->{'r'}
	     } else {
	       &toggle($s)
	     }
	   });
  toggle($s);
  $s->pan(1);
  return $s;
}

sub framed {
  shift;
  my ($id,$text) = @_;
  my $s = Tk::SlideShow::Sprite->New($id);
  my $c = Tk::SlideShow->canvas;
  my $t = $text || $id;
  my $idw = $c->createText(0,0,'-text',$t,
			   -justify, 'center',
			   -font => Tk::SlideShow->f1, -tags => $id);
  $c->createRectangle($c->bbox($idw), -fill,'light blue',-tags => $id);
  $c->raise($idw);
  $s->pan(1);
  return $s;
}


sub compuman {
  my ($p,$id) = @_;
  my $s = Tk::SlideShow::Sprite->New($id);
  my $can = $p->canvas;

  my @o1 = (-width ,4,-fill, 'black', -tags ,$id);
  my @o2 = (-fill,'blue', -tags ,$id);
  my @o3 = (-width ,4,-fill,'red', -tags ,$id);
  $can->createLine(qw(10 20 10 40 25 40 25 50),@o1); #chair
  $can->createLine(qw(15 15 15 35 30 35 30 50 35 50),@o1); # body
  $can->createOval(qw(11 11 18 18),@o2); # head
  $can->createLine(qw(15 25 30 25),@o1); # feet
  $can->createLine(qw(30 27 40 22),@o3); # keyborad
  $can->createPolygon(qw(35 20 40 0 55 10 55 20),@o3); # ecran
  $can->createLine(qw(45 20 45 30 35 30 35 30),@o3); # 
  ($s->{'x'},$s->{'y'}) = (0,0);
  $s->pan(1);
  return $s;
}

sub tickertape {
  my ($p,$id,$text,$len,%options) = @_;

  my $spri = $p->newSprite($id)->pan(1);
  my ($mw,$can,$H,$W) = ($p->mw,$p->canvas,$p->h,$p->w);
  my $delay = 50;
  my $chunk = 5;

  # extracting my own options
  if (exists $options{'-delay'}) {
    $delay = $options{'-delay'}; delete $options{'-delay'};}
  if (exists $options{'-chunk'}) {
    $chunk = $options{'-chunk'}; delete $options{'-chunk'};}
  my $idw = $can->createText(0,0,
			     '-text',substr($text,0,$len), 
			     -tags => $id,
			     %options
			    );
  my @bbox = $can->bbox($id);
  my $larg = $bbox[2]-$bbox[0];
  my $haut = $bbox[3]-$bbox[1];
  my $bg = $can->cget(-background);
  my $scan = $mw->Canvas(-height,$haut,-width,$larg,-background,$bg);
  $can->createWindow($W/2,$H/2,'-anchor','nw','-window',$scan,'-tags',$id);
  $can->delete($idw);
  my @def = (-anchor, 'nw','-text',$text,'-tags' => $id, %options);
  $idw = $scan->createText(0,0,@def);
  @bbox = $scan->bbox($idw);
  my $txtwidth = $bbox[2];
  $scan->createText($txtwidth,0, @def);
  $can->createRectangle($can->bbox($id),-width,20,-outline,$bg,-tags,$id);
  sub tourne {
    my ($spri,$can,$scan,$txtwidth,$delay,$chunk) = @_;
    my $tag = $spri->id;
    $scan->move($tag, (0 - $chunk) ,0);
    $scan->move($tag, $txtwidth,0) if ($scan->bbox($tag))[2] < $scan->Width;
    $can->after($delay,
		[\&tourne,$spri,$can,$scan,$txtwidth,$delay,$chunk]);
  }
  tourne($spri,$can,$scan,$txtwidth,$delay,$chunk);
  return $spri;
}

1;





