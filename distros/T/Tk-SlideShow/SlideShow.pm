use strict;

use Tk;
use Tk::Xlib;
use Tk::After;
use Tk::Animation;
use Tk::Font;

use Tk::SlideShow::Dict;
use Tk::SlideShow::Placeable;
use Tk::SlideShow::Diapo;
use Tk::SlideShow::Sprite;
use Tk::SlideShow::Oval;
use Tk::SlideShow::Link;
use Tk::SlideShow::Arrow;
use Tk::SlideShow::DblArrow;
use Tk::SlideShow::Org;


$SIG{__DIE__} = sub { print &pile;};

sub pile {
  my $i=0;
  my $str;
  while(my ($p,$f,$l) = caller($i)) {
    $str .= "\t$f:$l ($p) \n";
    $i++;
  } 
  return $str;
}

#------------------------------------------------
package Tk::SlideShow;
require Exporter;
use vars qw($VERSION @EXPORT @ISA);
@ISA=qw(Exporter);
@EXPORT=qw(template);
$VERSION='0.07';

my ($can,$H,$W,$xprot,$present);
my $mainwindow;
my $mode = 'X11';
my $family = "charter";
use vars qw($inMainLoop $nextslide $jumpslide);
$nextslide = 0;

sub var_getset{
  my ($s,$k,$v) = @_;
  if (defined $v) {$s->{$k} = $v; return $s;}
  else            {               return $s->{$k} ;}
};

sub family {
  my ($class,$newfamily) = @_;
  if (defined $newfamily) {$family = $newfamily;}
  return $family;
}
sub f {return $can->Font('family'  => $family, point   => int(150*(shift || 1)));}
sub ff {return $can->Font('family'  => 'courier', point   => int(250*(shift || 1)));}
sub f0_5  {return  $can->Font('family'  => $family, point   => 200);}
sub f1    {return  $can->Font('family'  => $family, point   => 250);}
sub f1_5  {return  $can->Font('family'  => $family, point   => 375);}
sub ff0_5 {return $can->Font('family'  => "courier", point   => 200);}
sub ff1   {return $can->Font('family'  => "courier", point   => 250);}
sub ff2   {return $can->Font('family'  => "courier", point   => 350);}
sub ff3   {return $can->Font('family'  => "courier", point   => 550);}
sub f2    {return  $can->Font('family'  => $family, point   => 500);}
sub f3 {return  $can->Font('family'  => $family, point => 750);}
sub f4 {return  $can->Font('family'  => $family, point => 1000);}
sub f5 {return  $can->Font('family'  => $family, point => 1250);}


sub mw { return $mainwindow;}
sub canvas {return $can }
sub h { return $H}
sub w { return $W}

sub present_start { var_getset((shift),'present_start',@_)};
sub diapo_start   { var_getset((shift),'diapo_start',@_)};
my $steps = 50;
sub steps { my ($s,$v) = @_;
	    return $steps unless defined $v;
	    $steps = $v;
	    return $s}


sub title_ne {
  my ($s,$texte) = @_;
  $can->createText($W,0,'-text',$texte,
		   -anchor => 'ne', -font => $s->f1, -fill => 'red');
}
sub title_se {
  my ($s,$texte) = @_;
  $can->createText($W,$H,'-text', $texte,
		   -anchor => 'se', -font => $s->f1, -fill => 'red');
}

# internal function for internals needs
my $current_item = "";

sub enter {
  $current_item = ($can->gettags('current'))[0]; 
#  my $s = Tk::SlideShow::Dict->Get($current_item);
#  print "entering $current_item\n"; 
#  $can->configure(-cursor, 'hand2');
}
sub leave {
#  print "leaving $current_item\n"; 
  $current_item = "";
#  $can->configure(-cursor, 'xterm');
}

sub current_item {
  return $current_item;
}


sub exec_if_current {
  my ($c,$tag,$fct,@ARGS) = @_;
#  print join('_',@_)."\n";
  if ($current_item eq $tag) {\&$fct(@ARGS);}
}

sub init {
  my ($class,$w,$h) = @_;
  my $m = new MainWindow;
  my $c = $m->Canvas;
  $can = $c;
  $mainwindow = $m;
  $present = bless { 'current' => 0, 'mw' => $m, 'fond'=>'ivory',
		   'slides_names' => {}};
  # This following part is there to force pointer to move
  # It is used for placing anchor of arrows.
  eval q{
      use X11::Protocol;
      $xprot = X11::Protocol->new();
  };
  warn $@ if $@;
  $H = $h || $m->Display->ScreenOfDisplay->HeightOfScreen;
  $W = $w || $m->Display->ScreenOfDisplay->WidthOfScreen;
  print ("H=$H, W=$W\n");
  $m->geometry('-0-20');
  $c->configure(-height,$H,-width,$W);
  $c->pack;
  $present->init_bindings;
  $present->init_choosers;
  return $present;
}

my $sens = 1;
my $setnextslide =  sub { $nextslide = 1;$sens = 1;};
my $setprevslide =  sub { $nextslide = 1;$sens = -1};

sub current {
  my ($class,$val) = @_;
  if (defined $val) {
    my $c;
    if ($val =~ /^\d+$/) {
      $c = $val;
    } else { 
      $c = $present->{'slides_names'}{$val} || 0;
    }
    $present->{'current'} = $c;
  } else {
    return $present->{'current'};
  }
}

sub warp {
  my ($class,$id,$event,$dest) = @_;
  $can->bind($id,$event, sub {$present->current($dest); $Tk::SlideShow::jumpslide = 1; })
}

sub save {
  Tk::SlideShow->addkeyhelp('Press s',
			      'To save sprite positions');

  $mainwindow->Tk::bind('Tk::SlideShow','<s>', [\&Tk::SlideShow::Placeable::save,$present]);
}

sub init_choosers {
  Tk::SlideShow::Sprite->initFontChooser;
  Tk::SlideShow::Sprite->initColorChooser;
}

sub load {
  shift;
  my $numero = $present->currentName;
  my $filename = shift || "slide-$numero.pl";
  print "Loading $filename ...";
  if (-e $filename) {
    do "./$filename";
    warn $@ if $@;
  }
  print "done\n";
}

sub currentName {
  my $c = $present->current;
  my %hn = %{$present->{'slides_names'}};
  while (my ($k,$v) = each %hn)  {
    return $k if $v eq $c;
  }
  return $c+1;
}

#internals
sub nbslides {shift; return scalar(@{$present->{'slides'}})}

sub bg {
  my ($class,$v) = @_;
  if (defined $v) {$present->{'fond'} = $v;} else {return $present->{'fond'};}
}

# internals
sub postscript {
  shift;
  my $nu = $present->current;
  $can->postscript(-file => "slide$nu.ps",
		   -pageheight => "29.7c",
		   -pagewidth => "21.0c",
		   -rotate => 1);
}
sub photos {
    my $title = $mainwindow->title;
    print "title $title\n";
    my $nu = (lc $title).".00";
    $nu++ while -f "$nu.gif";
    my $cmd = "xwd -name $title| xwdtopnm | ppmtogif > $nu.gif";
    print "command : $cmd\n";
    system $cmd;

}

#internals
sub warppointer {
  my ($x,$y) = @_;
  $xprot->WarpPointer(0, hex($can->id), 0, 0, 0, 0, $x, $y)
      if $xprot;
}

# this sub create a popup window with key binding help
{
  my %help;
  my $helpmenu;
  use Tk::DialogBox;
  sub addkeyhelp {
    shift if $_[0] eq 'Tk::SlideShow';
    my ($key,$texthelp) = @_;
    $help{$key} = $texthelp;
  }
  sub inithelpmenu {
    print "Initialising help menu\n";
    my $m = $mainwindow;
    $helpmenu = $m->DialogBox(-title,'Help',-buttons,['OK']);
    my $f = $helpmenu->add('Frame')->pack;
    my $t = $f->Scrolled('Text')->pack->Subwidget('text');
    $t->configure(-font,f0_5(),-height,20,-width,60);
    $t->tagConfigure('key',-foreground,'red');
    $t->tagConfigure('desc',-foreground,'blue');

    for (sort keys %help) {
      $t->insert('end',$_,'key',"\t$help{$_}",'desc',"\n");
    }
  }
  
  sub posthelp {
    print "posting menu\n";
    my $c = Tk::SlideShow->canvas;
    my $e = $c->XEvent;
    inithelpmenu unless defined $helpmenu;
    $helpmenu->Show;
    print "menu posted\n";
  }
  
}

sub init_bindings {
  shift;
  my ($m,$c) = ($mainwindow,$can);
  $m->bindtags(['Tk::SlideShow',$m,ref($m),$m->toplevel,'all']);
  $c->bindtags(['Tk::SlideShow']);#,$c,ref($c),$c->toplevel,'all']);
  $c->bind('all', '<Any-Enter>' => \&enter);
  $c->bind('all', '<Any-Leave>' => \&leave);
  $c->CanvasFocus;
  $m->Tk::bind('Tk::SlideShow','<3>', \&shiftaction);
  addkeyhelp('Click Button 3','To let slide evole one step');
  $m->Tk::bind('Tk::SlideShow','<Control-3>', \&unshiftaction);
  addkeyhelp('Click Ctrl-Button 3','To let slide evole one step back');
  $m->Tk::bind('Tk::SlideShow','<KeyPress-space>', $setnextslide);
  addkeyhelp('Press Space bar','to go to the next slide');
  $m->Tk::bind('Tk::SlideShow','<KeyPress-BackSpace>', $setprevslide);
  addkeyhelp('Press BackSpace','to go to the previous slide');
  $m->Tk::bind('Tk::SlideShow','<Alt-q>', sub {$m->destroy; exit});
  $m->Tk::bind('Tk::SlideShow','<Meta-q>', sub {$m->destroy; exit});
  $m->Tk::bind('Tk::SlideShow','<q>', sub {$m->destroy; exit});
  addkeyhelp('Press q','to quit');
  $m->Tk::bind('Tk::SlideShow','<p>', \&postscript);
  $m->Tk::bind('Tk::SlideShow','<P>', \&photos);
  $m->Tk::bind('Tk::SlideShow','<Up>', sub { print "curitem=$current_item"});
  $m->Tk::bind('Tk::SlideShow','<h>', \&posthelp);
  addkeyhelp('Press h','to get this help');
}


#internals
{ my $repeat_id;
  sub trace_fond {
    shift;
    my $m = $mainwindow;
    if (ref($present->bg) eq 'CODE') {
      &{$present->bg};
    } else {
      $can->configure(-background, $present->bg);
    }
    $repeat_id->cancel if defined $repeat_id;
    default_footer();
    $repeat_id = $m->repeat(5000,\&default_footer);
  }
}
#internals
sub wait {
  shift;
  while (Tk::MainWindow->Count)
    {
      Tk::DoOneEvent(0);
      last if $nextslide || $jumpslide;
    }
#  print "Je débloque\n";
  $nextslide = 0;
}

sub clean { 
  my $class = shift;
  $can->delete('all'); 
#  print "Afters : ".join('     ',$can->after('info'))."\n";
  for ($can->after('info')) { $can->Tk::after('cancel',$_);}
  $present->{'action'}= [];
  $present->{'save_action'}= [];
  Tk::SlideShow::Placeable->Clean;
  return $class;
}

sub a_warp {(shift)->arrive('direct',0,$H,@_); }
sub l_warp {(shift)->arrive('direct',0,-$H,@_); }
sub a_top  {(shift)->arrive('smooth',0,$H,@_); }
sub l_top  {(shift)->arrive('smooth',0,-$H,@_); }
sub a_bottom{(shift)->arrive('smooth',0,-$H,@_);}
sub l_bottom{(shift)->arrive('smooth',0,$H,@_);}
sub a_left{(shift)->arrive('smooth',$W,0,@_);}
sub l_left{(shift)->arrive('smooth',-$W,0,@_);}
sub a_right{(shift)->arrive('smooth',-$W,0,@_);}
sub l_right{(shift)->arrive('smooth',$W,0,@_);}

sub visible {
  my ($can,$tag) = @_;
  my ($b0,$b1,$b2,$b3) = $can->bbox($tag);
  return  ($b2 < 0 or $b3 < 0 or $b0 > $W or $b1 > $H ) ?
    0 : 1 ;
}

sub arrive {
  my ($class,$maniere,$dx,$dy,@tags) = @_;
  return  unless $mode eq 'X11';
  for my $tag (@tags) {
    if (ref($tag) eq 'ARRAY') {
      for (@$tag) {
	$can->move($_,-$dx,-$dy) if visible($can,$_);
	my $spri =  Tk::SlideShow::Dict->Get($_);
	for my $l ($spri->links) {$l->hide;}
      }
    } else { 
      $can->move($tag,-$dx,-$dy) if visible($can,$tag);
      my $spri =  Tk::SlideShow::Dict->Get($tag);
      for my $l ($spri->links) {$l->hide;}

    }
    push @{$present->{'action'}},[$tag,$maniere,$dx,$dy];
  }
  return $class;
}

sub a_multipos {
  my ($class,$tag,$nbpos,@options) = @_;
  for my $i (1..$nbpos) {
    push @{$present->{'action'}},[$tag,'a_chpos',$i,@options];
  }
}

sub shiftaction {
  my $a = shift @{$present->{'action'}};
  my $c = $can;
  return unless $a;
  push @{$present->{'save_action'}},$a;
  @_ = (@$a);
  my $tag = shift;
  my $maniere = shift;
  my $step = Tk::SlideShow->steps;
  $maniere eq 'smooth'  and 
    do {
      my ($dx,$dy) = @_;
      for(my $i=0;$i<$step;$i++){
	if (ref($tag) eq 'ARRAY') {
	  for (@$tag) {
	    $c->move($_,$dx/$step,$dy/$step);
	    my $spri = Tk::SlideShow::Dict->Get($_);
	    for my $l ($spri->links) {$l->show;}
	  }
	} else { 
	  $c->move($tag,$dx/$step,$dy/$step);
	  my $spri = Tk::SlideShow::Dict->Get($tag);
	  for my $l ($spri->links) {$l->show;}
	}
	$c->update;
      }

    };
  $maniere eq 'direct' and 
    do {
      my ($dx,$dy) = @_;
      if (ref($tag) eq 'ARRAY') {
	for (@$tag) {
	  $c->move($_,$dx,$dy);
	  my $spri = Tk::SlideShow::Dict->Get($_);
	  for my $l ($spri->links) {$l->show;}
	}
      } else { 
	$c->move($tag,$dx,$dy);
	my $spri = Tk::SlideShow::Dict->Get($tag);
	for my $l ($spri->links) {$l->show;}
      }
      $c->update;
    };
  $maniere eq 'a_chpos' and 
    do {
      my ($i,@options) = @_;
      #print "doing $m on tag $tag i=$i\n";
      my $sprite;
      if (ref($tag) eq 'ARRAY') {
	for (@$tag) {
	  $sprite = Tk::SlideShow::Sprite->Get($_);
	  $sprite->chpos($i,@options);
	}
      } else {
	$sprite = Tk::SlideShow::Sprite->Get($tag);
	$sprite->chpos($i,@options);
      }
    };
}
sub unshiftaction {
  my $a = pop @{$present->{'save_action'}};
  my $c = $can;
  return unless $a;
  unshift @{$present->{'action'}},$a;
  @_ = (@$a);
  my $tag = shift;
  my $maniere = shift;
  my $step = Tk::SlideShow->steps;
  $maniere eq 'smooth'  and 
    do {
      my ($dx,$dy) = @_;
      for(my $i=0;$i<$step;$i++){
	if (ref($tag) eq 'ARRAY') {
	  for (@$tag) {
	    $c->move($_,-$dx/$step,-$dy/$step);
	    my $spri = Tk::SlideShow::Dict->Get($_);
	    for my $l ($spri->links) {$l->show;}
	  }
	} else { 
	  $c->move($tag,-$dx/$step,-$dy/$step);
	  my $spri = Tk::SlideShow::Dict->Get($tag);
	  for my $l ($spri->links) {$l->show;}
	}
	$c->update;
      }
    };
  $maniere eq 'direct' and 
    do {
      my ($dx,$dy) = @_;
      if (ref($tag) eq 'ARRAY') {
	for (@$tag) {$c->move($_,-$dx,-$dy);}
      } else { $c->move($tag,-$dx,-$dy);}
      $c->update;
    };
  $maniere eq 'a_chpos' and 
    do {
      my ($i,@options) = @_;
      #print "doing $m on tag $tag i=$i\n";
      my $sprite;
      if (ref($tag) eq 'ARRAY') {
	for (@$tag) {
	  $sprite = Tk::SlideShow::Sprite->Get($_);
	  $sprite->chpos($i,@options);
	}
      } else {
	$sprite = Tk::SlideShow::Sprite->Get($tag);
	$sprite->chpos($i,@options);
      }
    };
}

sub start_slide { $present->clean->trace_fond; }

sub fin {
  $present->add(sub {
	    my $c = $can;
	    $present->start_slide;
	    $can->createText($W/2,$H/2, '-text',"FIN", -font, Tk::SlideShow->f5);
	  });
}

sub add {
  my ($class,$name,$sub) = @_;
  if (@_ == 2) {
    $sub = $name;
    $name = @{$present->{'slides'}};
  }
  
  my $diapo = Tk::SlideShow::Diapo->New($name,$sub);
  push @{$present->{'slides'}},$diapo;

  if (@_ == 3) { 
    $present->{'slides_names'}{$name} = @{$present->{'slides'}} - 1 ;
  }

  return $diapo;
}


sub play {
  my ($class,$timetowait) = @_;
  my $current = $present->current;
  $present->present_start(time);
  my $nbslides = @{$present->{'slides'}};
  while(1) {
    $jumpslide = 0;
    $current =  $present->current;
    my $diapo = $present->{'slides'}[$current];
    print "Executing slide number $current\n";
    $present->diapo_start(time);
    $present->start_slide;
    &{$diapo->code};
    if (defined $timetowait) {
      print "Sleeping $timetowait second\n";
      $mainwindow->update;
      sleep $timetowait;
      last if $current == $nbslides-1 ;
      print "Next one;\n";
    } else {
      $present->wait;
    }
#   print "jumpslide = $jumpslide\n";
    next if $jumpslide;
    $current += $sens;
    $current %= $nbslides;
    $present->current($current);
  }
}

sub latexheader {
  my ($p,$value) = @_;

  return ($p->{'latexheader'} || 
	  "\\documentclass{article}
\\usepackage{graphicx}
\\begin{document}
")
    unless defined $value;

  $p->{'latexheader'} = $value;
  return $p;
}

sub latexfooter {
  my ($p,$value) = @_;

  return ($p->{'latexfooter'} || 
	  "\\end{document}")
    unless defined $value;

  $p->{'latexfooter'} = $value;
  return $p;
}

# saving diapo in a single latex file
sub latex {
  my ($s,$latexfname) = @_;
  $mode ='latex';
  my $nbdiapo = @{$present->{'slides'}};

  open(OUT,">$latexfname") or die "$!";
  print OUT latexheader();
  for (my $i=0; $i<$nbdiapo; $i++) {
    $present->current($i);
    print "Loading slide : ".$s->currentName."\n";
    $s->start_slide;
    my $diapo = $present->{'slides'}[$i];
    &{$diapo->code};
    $mainwindow->update;
    my $file = 'slide'.$diapo->name.'.ps';
    $can->postscript(-file => $file);
    print OUT "\\includegraphics[width=\\textwidth]{$file}\n";
    print OUT "".$diapo->latex;
    print OUT "\n\\newpage";
  }
  print OUT latexfooter();
  close OUT;
  
}

# building an html index and gif snapshots
sub htmlheader {return ""}
sub htmlfooter {return ""}
sub html {
  my ($s,$dirname) = @_;
  $mode = 'html';
  my $nbdiapo = @{$present->{'slides'}};

  if(not -d "$dirname") {
    mkdir $dirname,0750 or die "$!";
  }
  open(INDEX,">$dirname/index.html") or die "$!";
  print INDEX $s->htmlheader;
  for (my $i=0; $i<$nbdiapo; $i++) {
    $present->current($i);
    my $name = $s->currentName;
    print "Loading slide $name\n";
    $s->start_slide;
    my $diapo = $present->{'slides'}[$i];
    &{$diapo->code};
    $mainwindow->update;
    my $fxwd_name = "/tmp/tkss.$$.xwd";
    my $f_name = "$dirname/$name.gif";
    my $fm_name = "$dirname/m.$name.gif";
    my $fs_name = "$dirname/s.$name.gif";
    my $title = $mainwindow->title;
    print "Snapshooting it (xwd -name $title -out $fxwd_name)\n";
    system("xwd -name $title -out $fxwd_name");
    print "Converting to gif\n";
    system("convert $fxwd_name $f_name");
    my ($w,$h) = ($s->w,$s->h);
    my ($mw,$mh) = (int($w/2),int($h/2));
    print "Rescaling it for medium gif (${mw}x${mh}) access\n";
    system("convert -sample ${mw}x${mh} $f_name $fm_name");
    my ($sw,$sh) = (int($w/4),int($h/4));
    print "Rescaling it for small gif (${sw}x${sh}) access\n";
    system("convert -sample ${sw}x${sh} $f_name $fs_name");
    print INDEX "<li> <a href='$name.html'> $name  </a></li><br> 
                 <a href=m.$name.gif> <img src=s.$name.gif> </a> \n";
    open(HTML,">$dirname/$name.html") or die "$!";
    print HTML "<img src=$name.gif><br>\n";
    print HTML $diapo->html;
    close HTML;
  }
}

# make an abstract of slides
sub latexabstract {
  my ($s,$latexfname) = @_;
  $mode ='latex';
  my $nbdiapo = @{$present->{'slides'}};

  open(OUT,">$latexfname") or die "$!";
  print OUT latexheader();
  for (my $i=0; $i<$nbdiapo; $i++) {
    $present->current($i);
    print "Chargement de la diapo : ".$s->currentName."\n";
    $s->start_slide;
    my $diapo = $present->{'slides'}[$i];
    &{$diapo->code};
    $mainwindow->update;
    my $file = 'slide'.$diapo->name.'.ps';
    $can->postscript(-file => $file);
    print OUT "\\noindent\\includegraphics[width=.5\\textwidth]{$file}\n";
    print OUT "";
  }
  print OUT latexfooter();
  close OUT;
}

sub default_footer {
  my $now = time;
#  print "default footer displaying\n";
#  my $td = $now - $present->diapo_start;
#  my $tp = $now - $present->present_start;
  my $num = $present->current+1;
  my $nbs = $present->nbslides;
  my $name = $present->currentName;
#  $td = $td>60 ? sprintf("%s'%ss",int($td/60),$td%60) : "${td}s";
#  $tp = $tp>60 ? sprintf("%s'%ss",int($tp/60),$tp%60) : "${tp}s";
    
#  my $t = "$name($num($td))/$nbs($tp))";
  my $t = "$name($num/$nbs)";
  $can->delete('footer');
  $can->createText(10,$H - 10,'-text',$t,-anchor,'sw',
		   -tags,'footer');
}

sub template {
  print qµ#!/usr/local/bin/perl5

use Tk::SlideShow;
use strict;

my $p = Tk::SlideShow->init(1024,768) or die;

$p->save;

my ($mw,$c,$h,$w) = ($p->mw, $p->canvas, $p->h, $p->w);
my $d;

#--------------------------------------------
$d = $p->add('summary',
	     sub {
	       title('First title');
	       my @ids = items('a0',"item1 \n item2 \n item3",
			       -font => $p->f2,-fill, 'red');
	       $p->load;
	       $p->a_top(@ids);
	     });

$d->html(" ");

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
sub example {
  my ($id,$t,@options) = @_;
  $t =~ s/^\s+//; $t =~ s/\s+$//;
  my $s = $p->newSprite($id);
  my $f = $c->Font('family'  => "courier", point => 250, -weight => 'bold');
  $c->createText(0,0,-text,'Example',
		 -font => $f, -tags => $id, 
		 -fill,'red',
		 -anchor => 'sw');
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
µ;
}

# wrappers

sub newSprite {shift; return Tk::SlideShow::Sprite->New(@_);}
sub newLink   {shift; return Tk::SlideShow::Link->New(@_);  }
sub newArrow   {shift; return Tk::SlideShow::Arrow->New(@_);  }
sub newDblArrow   {shift; return Tk::SlideShow::DblArrow->New(@_);  }
sub newOrg    {shift; return Tk::SlideShow::Org->New(@_);  }


sub Text {return Tk::SlideShow::Sprite::text(@_);}
sub Framed {return Tk::SlideShow::Sprite::framed(@_);}
sub Image {return Tk::SlideShow::Sprite::image(@_);}
sub Anim {return Tk::SlideShow::Sprite::anim(@_);}
sub Oval {return Tk::SlideShow::Oval::New(@_);}

sub TickerTape {return Tk::SlideShow::Sprite::tickertape(@_);}
sub Compuman {return Tk::SlideShow::Sprite::compuman(@_);}

1;

# Local Variables: ***
# mode: perl ***
# End: ***


__END__


