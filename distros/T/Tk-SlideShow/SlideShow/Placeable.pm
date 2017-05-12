#----------------------------------------
# PLACEABLE
#----------------------------------------
#
# Class for managing placeable objets
#

use strict;

package Tk::SlideShow::Placeable;

use vars qw(@ISA @classes);
@ISA = qw(Tk::SlideShow::Dict);


sub New {
  my ($class,$id) = @_;
  die "An mandatory id is needed !" unless defined $id;
  my $s = bless {'x'=>Tk::SlideShow->w/2,'y'=>Tk::SlideShow->h/2,'id'=>$id,
		'link' => []};
  $class->Set($id,$s);
  return $s;
}

sub x { return (shift)->{'x'};}
sub y { return (shift)->{'y'};}
sub xy { my $s = shift; return ($s->{'x'},$s->{'y'})};

sub no { 
  my $s = shift;
  my ($x1,$y1,$x2,$y2) = Tk::SlideShow->canvas->bbox($s->id);
#  print "bbox(".$s->id." = $x1,$y1,$x2,$y2\n";
  return ($x1,$y1);
}
sub n { 
  my $s = shift;
  my ($x1,$y1,$x2,$y2) = Tk::SlideShow->canvas->bbox($s->id);
  return (($x1+$x2)/2,$y1);
}
sub ne { 
  my $s = shift;
  my ($x1,$y1,$x2,$y2) = Tk::SlideShow->canvas->bbox($s->id);
  return ($x2,$y1);
}
sub e { 
  my $s = shift;
  my ($x1,$y1,$x2,$y2) = Tk::SlideShow->canvas->bbox($s->id);
  return ($x2,($y1+$y2)/2);
}
sub se { 
  my $s = shift;
  my ($x1,$y1,$x2,$y2) = Tk::SlideShow->canvas->bbox($s->id);
  return ($x2,$y2);
}
sub s { 
  my $s = shift;
  my ($x1,$y1,$x2,$y2) = Tk::SlideShow->canvas->bbox($s->id);
  return (($x1+$x2)/2,$y2);
}
sub so { 
  my $s = shift;
  my ($x1,$y1,$x2,$y2) = Tk::SlideShow->canvas->bbox($s->id);
  return ($x1,$y2);
}
sub o { 
  my $s = shift;
  my ($x1,$y1,$x2,$y2) = Tk::SlideShow->canvas->bbox($s->id);
  return ($x1,($y1+$y2)/2);
}

sub pos {
  my $s = shift;
  my $pos = shift;
  $pos = ( $pos + 8 ) % 8;
#  print "returning pos of ".$s->id." at $pos\n";
  return $s->no if $pos == 0;
  return $s->n  if $pos == 1;
  return $s->ne if $pos == 2;
  return $s->e  if $pos == 3;
  return $s->se if $pos == 4;
  return $s->s  if $pos == 5;
  return $s->so if $pos == 6;
  return $s->o  if $pos == 7;
  return (0,0);
}

sub addLink {
  my ($s,$l) = @_;
  push @{$s->{'link'}},$l;
}

sub links { return @{(shift)->{'link'}};}


sub id { return (shift)->{'id'};}

sub evalplace {
  my $s = shift;
  die "La méthode 'evalplace' doit être redéfinie pour la classe ".ref($s)." et ne l'est pas, apparament\n";
}
use Cwd;


sub save {
  shift;
  my $slides = shift;

  my $numero = $slides->currentName;
  my $dfltfname = "slide-$numero.pl";
  my %files = ();
  print "saving slide $numero\n";
  for my $id ( Tk::SlideShow::Dict->All) {
    my $s = Tk::SlideShow::Dict->Get($id);
#    print "Saving $id of class :".ref($s)."\n";
    next if $id eq '__null__';
    $id =~ s/['\\]/\\$&/g;
    my $fname = ($id =~ m|/|) ? $`: $dfltfname ;
    $files{$fname} .= "Tk::SlideShow::Dict->Get('$id')->".$s->evalplace.";\n";
  }
  while(my($k,$v) = each %files) {
    print "Generating file  $k\n";
    open(OUT,">$k") or die;
    print OUT $v;
    close OUT;
  }
};


sub Clean {
  Tk::SlideShow::Dict->Clean;
}


sub pan {
  my ($s,$button) = @_;
  my $c = Tk::SlideShow->canvas;
  Tk::SlideShow->addkeyhelp('Press Button 1 and move, on canvas items',
			    'to drag them');
  my $id = $s->id;
  Tk::SlideShow->addkeyhelp("Press Ctrl-Button 1 on canvas items",
			      'to lower them');

  $c->bind($id,"<Control-$button>", sub {$c->lower($id)});
  $c->bind($id,"<$button>", 
	   sub { 
	       my $e = (shift)->XEvent;
	       #	       my $id = $s->id;
#	       print "B1 pressed\n";
	       $c->raise($id);
	       ($s->{'sx'},$s->{'sy'}) = ($c->canvasx($e->x),$c->canvasy($e->y));
	     });
  $c->bind($id,"<B$button-Motion>", 
	   sub {
#	     print "B1 motion\n";
	     my $e = (shift)->XEvent;
#	     my $id = $s->id;
	     my ($nx,$ny) = ($c->canvasx($e->x),$c->canvasy($e->y));
	     my ($dx,$dy) = ($nx-$s->{'sx'},$ny-$s->{'sy'});
	     $c->move($id, $dx,$dy);
	     ($s->{'sx'}, $s->{'sy'}) = ($nx,$ny);
	     $s->{'x'} += $dx; $s->{'y'} += $dy; 
	     for my $l ($s->links) {$l->show;}

	   });
  return $s;
}

sub cursor {
  my ($s,$cursorname) = @_;
  my $c = Tk::SlideShow->canvas;
  my $id = $s->id;
  $c->bind($id, '<Enter>',sub { $c->configure(-cursor,$cursorname)});
  $c->bind($id, '<Leave>',sub { $c->configure(-cursor,'top_left_arrow')});
}


1;
