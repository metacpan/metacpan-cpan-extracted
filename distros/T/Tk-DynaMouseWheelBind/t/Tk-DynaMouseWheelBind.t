use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 12;
use Test::Tk;

require_ok ('Tk::DynaMouseWheelBind');

sub getref {
	my $class = shift;
	my $name = ref $class;
	return $name
}

createapp;
my ($t, $c, $p, $e);
if (defined $app) {
	$e = $app->Entry->pack;
	$app->DynaMouseWheelBind('Tk::Canvas',
	                        'Tk::Text',
	                        'Tk::Pane',
	                    );
	
	
	$t = $app->Scrolled('Text', -height => 10 )->pack();
	$t = $t->Subwidget('scrolled');
	$t->insert('end', "line $_\n") for (1..100);
	
	$c = $app->Scrolled('Canvas',
	                      -scrollregion => [0,0,1000,1000],
	                      -bg           => 'white',
	                      )->pack;
	$c = $c->Subwidget('scrolled');
	
	$c->createText(50,250,
	               -text => 'a text item',
	           );
	
	
	$p = $app->Scrolled('Pane')->pack;
	$p = $p->Subwidget('scrolled');
	
	for (1..20){
	    $p->Entry->pack;
	}
	$app->update;
	
	for ($p, $c, $t){
	    $_->yview(moveto => .5);
	}
	$e->focus;
	$app->update;
	
}

for (['<5>'],['<4>'],['<MouseWheel>',-delta => -120]){
	my $ev = $_;
	for my $w($t, $c, $p){
		push @tests, [sub {
			$w->eventGenerate('<Enter>');
			my $y = ($w->yview)[0];
			$e->eventGenerate(@$ev);
			pause(200);
			my $delta = abs ($y - ($w->yview)[0]);
			return $delta > 0.01
		}, 1, getref($w) . " scrolling delta " . $ev->[0]]
    }
}

starttesting;
