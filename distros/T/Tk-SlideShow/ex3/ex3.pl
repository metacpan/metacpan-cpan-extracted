#!/usr/local/bin/perl5 -I../blib/lib

use Tk::SlideShow;
use strict;
	
my $p = init Tk::SlideShow(1024,768);
$p->save;
my ($mw,$c,$h,$w) = ($p->mw, $p->canvas, $p->h, $p->w);

sub bandeau {
  my ($id,$text,$len) = @_;
  my $spri = $p->newSprite($id)->pan(1);
  $spri->{'text'}=$text;
  $spri->{'offset'} = 0;
  $spri->{'len'} = $len;
  $spri->{'idw'} = $c->createText(0,0,-text,"", -font => $p->f2, -fill => 'red', -tags => $id,);
  sub tourne {
    my $spri = shift;
    my $tag = $spri->id;
    my $len = $spri->{'len'};
    my $offset = $spri->{'offset'};
    my $text = $spri->{'text'};
    my $L = length($text);
    my $idw = $spri->{'idw'};
    $c->dchars($idw,'0','end');
    my $newtext = substr($text,$offset,$len);
    $newtext .= substr($text,0,$len-($L-$offset))
      if ($L-$offset < $len);
    $c->insert($idw,'end',$newtext);
    $spri->{'offset'} ++;
    $spri->{'offset'} %= $L;
    $c->after(100,[\&tourne,$spri]);
  }
  tourne($spri);
  return $spri;
}

$p->bg('black');

$p->add('bandeau', sub {
	  $p->Text('titre','Animations',-font=>$p->f3);
	  bandeau('m',"Tk::SlideShow has no cause to be jealous of PowerPoint ...... ", 40);
	  $p->load });

$p->current(shift || 0);
$p->play;




