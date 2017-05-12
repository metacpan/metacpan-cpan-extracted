#!/usr/local/bin/perl5
# Date de création : Sat May 29 08:54:05 1999
# par : Olivier Bouteille (oli@localhost.oleane.com)

open(IN,"rgb.txt") or die;
use Tk;

while(<IN>) {
  next if /^!/;
  my ($r,$v,$b,$c) = /(\d+)\s+(\d+)\s+(\d+)\s+(\w.*)$/;
  $col{$c} = [$r,$v,$b];
#  print "$c = [$r,$v,$b]\n";
}
close IN;

my $n = shift || 6;

my $delta = int(255/($n+1));
my $mw = new MainWindow;

my $can = $mw->Canvas->pack;

$mw->update;
my ($x,$y)=(0,0);
for ($i = 0; $i < $n; $i++) {
  my $r = ($i+1)*$delta;
  for ($j = 0; $j < $n; $j++) {
    my $v = ($j+1)*$delta;
    for ($k = 0; $k < $n; $k++) {
      my $b = ($k+1)*$delta;
      print "recherche de la couleur approchant plus ($r,$v,$b)\n";
      my ($colbest,$best);
      $best = 100000;
      while(($col,$p) = each %col) {
	my ($r0,$v0,$b0) = @$p;
	$dist = ($r-$r0)**2+($v-$v0)**2+($b-$b0)**2;
	if ($dist < $best) {
	  $colbest = $col;
	  $best = $dist;
	}
      }
      print "trouvé : $colbest : ".join(",",@{$col{$colbest}})." : distance $best\n";
      push @colbest,$colbest;
      $can->createRectangle($x,$y,$x+10,$y+10,-fill,$colbest);
      $mw->update;
      $x+=12;
      if ($x>200) {$y += 12; $x = 0;}
    }
  }
}

MainLoop;


# Local Variables: ***
# mode: perl ***
# End: ***


