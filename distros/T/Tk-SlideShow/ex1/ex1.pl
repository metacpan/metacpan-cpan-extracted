#!/usr/local/bin/perl5 -I../blib/lib -w

use Tk::SlideShow;
use strict;

my $p =  Tk::SlideShow->init(1024,768);

my ($mw,$c,$h,$w) = ($p->mw, $p->canvas, $p->h, $p->w);

$p->save;

my @plan = (
	    'intro'      => "Introduction",
	    'pos'        => "Problem Position",
	    'present'    => "Presentation",
	    'dev'        => "Development",
	    'solutions'  => "Solutions",
	    'conclusion' => "Conclusion" );


sub box {
  my ($id,$text,$who) = @_;
  my $color = ($who eq $id) ? 'light pink' : 'light blue';
  my $sp = $p->newSprite($id);
  my $idw = $c->createText(0,0,-text,$text,
			   -font => $p->f0_5,
			   -justify => 'center',
			   -tags => $id);
  $c->createRectangle($c->bbox($idw),
		      -fill => $color,
		      -tags => $id);

  my $orgname = $id;
  $orgname =~ s|org/||;
  $p->warp($id,'<Double-1>',$orgname);

  $c->raise($idw);
  $sp->pan(1);
  return $sp;
}


sub small_summary {
  my $count = 0;
  my @p = @plan;
  while(@p) {
    my ($diapo,$titre) = (shift @p, shift @p);
    my $id = "som/i$count";
    my $color = 'blue'; 
    my $font = $p->f0_5;
    if ($p->currentName eq $diapo) {
      $color = 'red';
      $font = $p->f1;
    }
    $p->Text($id,$titre,-font,$font, -fill,$color,-anchor,'w');
    $p->warp($id,'<Double-1>',$diapo);
    $count ++;
  }
  $p->load('som');
}

sub organigramme {
  my $who = shift || 'personne';
  my $chef = box('org/c','The boss',$who);
  my $b1 = box('org/c_b1',"First\nsection",$who);
  my $b2 = box('org/c_b2',"Second\nsection",$who);
  my $b11 = box('org/c_b1_1',"First\nOffice",$who);
  my $b12 = box('org/c_b1_2',"Second\nOffice",$who);
  my $b13 = box('org/c_b1_3',"Third\nOffice",$who);
  my $b21 = box('org/c_b2_1',"First\nOffice",$who);
  my $b22 = box('org/c_b2_2',"Second\nOffice",$who);
  my $b111 = $p->Image('org/oli','Xcamel.gif');
  $p->newOrg ($chef,$b1);
  $p->newOrg ($chef,$b2);
  for ($b11,$b12,$b13) {$p->newOrg($b1,$_);}
  for ($b21,$b22) {$p->newOrg($b2,$_);}
  $p->newOrg($b11,$b111);
  
  $p->load('org');
}

sub title {
  my $title = shift;
  $p->Text('title',$title,-font,$p->f3);
}

$p->add('summary',sub {
	  title "Summary";
	  my @p = @plan;
	  my $count = 0;
	  while(@p) {
	    my ($diapo,$titre) = (shift @p, shift @p);
	    $p->Text("i$count",$titre,-font,$p->f2,-fill,'blue');
	    $count ++;
	  }
	  $p->load;
	  $p->a_left(map {"i$_"} (0..($count-1)));
});

$p->add('intro',sub {
	  title "Introduction";
	  $p->load;
	  &small_summary;
	  &organigramme;
});
$p->add('pos',sub {
	  title "Pb Position";
	  $p->load;
	  &small_summary;
});
$p->add('present',sub {
	  title "Presentation";
	  $p->load;
	  &small_summary;
	  &organigramme('org/c_b1');
});
$p->add('c_b1',sub {
	  title "The first section";
	  $p->load;
	  &small_summary;
	  &organigramme('org/c_b1');
});
$p->add('dev',sub {
	  title "Developpment";
	  $p->load;
	  &small_summary;
	  &organigramme('org/c_b2');
});
$p->add('solutions',sub {
	  title "Good Solutions";
	  $p->load;
	  &small_summary;
	  &organigramme('org/c_b1_1');

});
$p->add('conclusion',sub {
	  title "Conclusion";
	  $p->load;
	  &small_summary;
});
$p->fin;

$p->current(shift || 0);
$p->play;



