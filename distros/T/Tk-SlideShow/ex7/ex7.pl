#!/usr/local/bin/perl5 

use lib qw(../blib/lib);
use Tk::SlideShow 0.07;
use strict;

my $p = Tk::SlideShow->init(1024,768) or die;
$p->save;
my ($mw,$c,$h,$w) = ($p->mw, $p->canvas, $p->h, $p->w);
my $d;

sub example {
  my ($id,$t,@options) = @_;
  $t =~ s/^\s+//; $t =~ s/\s+$//;
  my $s = $p->newSprite($id);
  my $f = $c->Font('family'  => "courier", point => 250, -weight => 'bold');
  $c->createText(0,0,-text,'Exemple',
		 -font => $f, -tags => $id, 
		 -fill,'red',
		 -anchor => 'sw');
  my $tw = $mw->Text(-font => $f, -width => 45, -height => 20);
  for (split(/\n/,$t)) {
    if (/^#/) {
      $tw->insert("end","$_\n","comment");
    } else {
      $tw->insert("end","$_\n");
    }
  }
  $tw->tagConfigure('comment',-foreground,'green',-background,'black');
  $tw->insert('end',$t);
  $tw->configure('state'=>'disable');
  my $idw = $c->createWindow(0,0,-window, $tw, -tags => $id,
			  -anchor => 'nw');
  $c->createRectangle($c->bbox($idw), -fill,'black',-tags => $id);
  $c->lower($idw);
  $s->pan(1);
  return $s;
}

sub pp {
  my ($id,$text) = @_;
  
  $p->newArrow($p->Text("t$id",$text,-font,$p->f2),
	      $p->Oval("o$id",-width,3,-outline,'red'),
	      '',-fill,'red',-width,2);
}
$d = $p->add('summary',
	     sub {
	       title('Example 7');
	       example("ex1",'# This is a perl source of this example :

$p->add("summary",
	title("Example 7");

	example("ex1","This is quasi .. 
	the perl source of this example ... ");

	pp("a1","Start");
	pp("a2","End");
	$p->load;
);
#
# Simple isn\'t it ? ..  and useful if you 
# have to do it often in your presentations
# Of course function example an pp are to
# written, but only once ... this is the plus
# of using perl for presentations
#


');
	       pp('a1',"Start");
	       pp('a2',"End");
	       $p->load;
	     });


#--------------------------------------------

$d->html(" ");

sub title { $p->Text('title',shift,-font,$p->f3); }


$p->current(shift || 0);
$p->play;
