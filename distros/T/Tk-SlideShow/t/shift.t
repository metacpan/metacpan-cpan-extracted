
use Tk::SlideShow;
use strict;

chdir('t');
print "1..11\n";	
my $p = Tk::SlideShow->init(1024,768);
$p->save;
my ($mw,$c,$h,$w) = ($p->mw, $p->canvas, $p->h, $p->w);
my $nbok = 1;
$p->add('left', 
	sub {
	  for (1..10) {$p->Text("shift/i$_","Text$_");}
	  $p->load('shift') ;
	  $p->a_left(map {"shift/i$_"}(1..10));
	  $p->l_left(map {"shift/i$_"}(1..10));
	  $p->a_left(map {"shift/i$_"}(1..10));
	  for (1..30) {$p->shiftaction;}
	  print "ok $nbok\n"; $nbok++;
	});
$p->add('pleft', 
	sub {
	  for (1..10) {$p->Text("shift/i$_","Text$_");}
	  $p->load('shift') ;
	  $p->a_left([map {"shift/i$_"}(1..10)]);
	  $p->l_left([map {"shift/i$_"}(1..10)]);
	  $p->a_left([map {"shift/i$_"}(1..10)]);
	  for (1..3) {print "  shift $_\n";$p->shiftaction;}
	  for (1..3) {print "unshift $_\n";$p->unshiftaction;}
	  print "ok $nbok\n"; $nbok++;

	});
$p->add('right', 
	sub {
	  for (1..10) {$p->Text("shift/i$_","Text$_");}
	  $p->load('shift') ;
	  $p->a_right(map {"shift/i$_"}(1..10));
	  $p->l_right(map {"shift/i$_"}(1..10));
	  $p->a_right(map {"shift/i$_"}(1..10));
	  for (1..30) {$p->shiftaction;}
	  print "ok $nbok\n"; $nbok++;
	});
$p->add('pright', 
	sub {
	  for (1..10) {$p->Text("shift/i$_","Text$_");}
	  $p->load('shift') ;
	  $p->a_right([map {"shift/i$_"}(1..10)]);
	  $p->l_right([map {"shift/i$_"}(1..10)]);
	  $p->a_right([map {"shift/i$_"}(1..10)]);
	  for (1..3) {$p->shiftaction;}
	  print "ok $nbok\n"; $nbok++;
	});
$p->add('top', 
	sub {
	  for (1..10) {$p->Text("shift/i$_","Text$_");}
	  $p->load('shift') ;
	  $p->a_top(map {"shift/i$_"}(1..10));
	  $p->l_top(map {"shift/i$_"}(1..10));
	  $p->a_top(map {"shift/i$_"}(1..10));
	  for (1..30) {$p->shiftaction;}
	  print "ok $nbok\n"; $nbok++;
	});
$p->add('ptop', 
	sub {
	  for (1..10) {$p->Text("shift/i$_","Text$_");}
	  $p->load('shift') ;
	  $p->a_top([map {"shift/i$_"}(1..10)]);
	  $p->l_top([map {"shift/i$_"}(1..10)]);
	  $p->a_top([map {"shift/i$_"}(1..10)]);
	  for (1..3) {$p->shiftaction;}
	  print "ok $nbok\n"; $nbok++;
	});
$p->add('bottom', 
	sub {
	  for (1..10) {$p->Text("shift/i$_","Text$_");}
	  $p->load('shift') ;
	  $p->a_bottom(map {"shift/i$_"}(1..10));
	  $p->l_bottom(map {"shift/i$_"}(1..10));
	  $p->a_bottom(map {"shift/i$_"}(1..10));
	  for (1..30) {$p->shiftaction;}
	  print "ok $nbok\n"; $nbok++;
	});
$p->add('pbottom', 
	sub {
	  for (1..10) {$p->Text("shift/i$_","Text$_");}
	  $p->load('shift') ;
	  $p->a_bottom([map {"shift/i$_"}(1..10)]);
	  $p->l_bottom([map {"shift/i$_"}(1..10)]);
	  $p->a_bottom([map {"shift/i$_"}(1..10)]);
	  for (1..3) {$p->shiftaction;}
	  print "ok $nbok\n"; $nbok++;
	});
$p->add('warp', 
	sub {
	  for (1..10) {$p->Text("shift/i$_","Text$_");}
	  $p->load('shift') ;
	  $p->a_warp(map {"shift/i$_"}(1..10));
	  $p->l_warp(map {"shift/i$_"}(1..10));
	  for (1..20) {$p->shiftaction;}
	  print "ok $nbok\n"; $nbok++;
	});
$p->add('multipos', 
	sub {
	  $p->Text('fix','Fixed Text');
	  my $s= $p->Compuman("t");
	  $p->newLink('t','fix');
	  my @a = (0,0,$w-100,int($h/2),0,$h-100);
	  $p->a_multipos('t',2,-speed,1000,-steps, 2);
	  $s->multipos(@a);
	  for (1..2) {$p->shiftaction; sleep(2)}
	  print "ok $nbok\n"; $nbok++;
	});
$p->add('pmultipos', 
	sub {
	  my $s1 = $p->Compuman("t1");
	  my $s2 = $p->Compuman("t2");
	  my $div = 3;
	  my (@a1,@a2);
	  for my $i (0..($div-1)) {for my $j (0..($div-1)) {
	    push @a1,int($i*$w/$div),int($j*$h/$div);
	    push @a2,int($i*$w/$div)+50,int($j*$h/$div)+50;
	  }}
	  $p->a_multipos([qw(t1 t2)],$div*$div - 1,-speed,1000,-steps, 10);
	  $s1->multipos(@a1);
	  $s2->multipos(@a2);
	  for (1..$div**2) {$p->shiftaction;}
	  print "ok $nbok\n"; $nbok++;
	});

if (grep /^-abstract$/,@ARGV) {
  $p->latexabstract("abstract.tex");
  exit 0;
}

$p->current($ARGV[0] || 0);

if (@ARGV) {
  $p->play;
} else {
  $p->play(1);
}
