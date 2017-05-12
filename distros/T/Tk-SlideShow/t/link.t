
use Tk::SlideShow;
use strict;

chdir('t');
print "1..5\n";	
my $p = Tk::SlideShow->init(1024,768);
$p->save;
my ($mw,$c,$h,$w) = ($p->mw, $p->canvas, $p->h, $p->w);

$p->add('dblarrow', 
	sub { 
	my $id = 'id1';	
	$p->newDblArrow($p->Text($id++,"TOTO $id"), $p->Text($id++,"TITI $id" ));	
	$p->newArrow($p->Text($id++,"TOTO $id"), $p->Text($id++,"TITI $id" ));	
	$p->newDblArrow($p->Text($id++,"TOTO $id"), $p->Text($id++,"TITI $id" ),"Title $id double arrow");
	$p->newArrow($p->Text($id++,"TOTO $id"), $p->Text($id++,"TITI $id"),"title $id" );
	$p->newDblArrow($p->Text($id++,"TOTO $id"), $p->Text($id++,"TITI $id"),"Double arrow",-fill,'red' );
	$p->newArrow($p->Text($id++,"TOTO $id"), $p->Text($id++,"TITI $id"),"title $id",-fill,'blue');
	$p->load ;
	print "ok 1\n";
      });

$p->add('arrow', 
	sub {
	  my $last = $p->Text('i0','Origin');
	  for my $i (1..10) {
	    my $cur = $p->Text("i$i","Text$i");
	    $p->newArrow($last,$cur);
	    $last = $cur;
	  }
	    
	  $p->load ;
	  print "ok 2\n";
	});

$p->add('link',
	sub {
	  my $last = $p->Text('i0','Origin');
	  for my $i (1..10) {
	    my $cur = $p->Text("i$i","Text$i");
	    $p->newLink($last,$cur);
	    $last = $cur;
	  }
	  $p->load ;
	  print "ok 3\n";
	  
	}
);
$p->add('org',
	sub {
	  my $last = $p->Text('i0','Origin');
	  for my $i (1..10) {
	    my $cur = $p->Text("i$i","Text$i");
	    $p->newOrg($last,$cur);
	    $last = $cur;
	  }
	  $p->load ;
	  print "ok 4\n";
	  
	}
);
$p->add('linkarrive',
	sub {
	  my $last = $p->Text('i0','Origin');
	  for my $i (1..10) {
	    my $cur = $p->Text("i$i","Text$i");
	    $p->newLink($last,$cur,"Link $i",-width, 4, );
	    $last = $cur;
	  }
	  $p->load ;
	  $p->a_bottom(map {"i$_"}(1..10));
	  for (1..10) {$p->shiftaction;}

	  print "ok 5\n";
	  
	}
);
$p->current($ARGV[0] || 0);
if (@ARGV) {
  $p->play;
} else {
  $p->play(1);
}
