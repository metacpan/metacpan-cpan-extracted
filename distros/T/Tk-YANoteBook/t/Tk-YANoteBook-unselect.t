
use strict;
use warnings;
use Test::Tk;
use Tk;
require Tk::Adjuster;

use Test::More tests => 4;
BEGIN { use_ok('Tk::YANoteBook') };

$delay = 1500;

createapp;

my $nb;
if (defined $app) {
	my $nbf = $app->Frame(-relief => 'groove', -borderwidth => 4);
	my $adjuster;
	$nb = $nbf->YANoteBook(
#		-background => 'red',
#		-relief => 'groove',
#		-borderwidth => 4,
		-autoupdate => 1,
		-onlyselect => 0,
		-rigid => 0,
		-selecttabcall => sub {
			my $t = shift;
# 			print "select $t\n";
# 			$nb->packForget;
# 			$nb->pack(-expand => 1, -fill => 'both');
			my $pf = $nb->Subwidget('PageFrame');
			my $tf = $nb->Subwidget('TabFrame');
			my $offset = ($tf->cget('-borderwidth') + $nb->cget('-borderwidth')) * 2;
# 			print "offset $offset\n";
#			$nb->GeometryRequest($nb->width, $tf->height + $offset + $pf->reqheight);
#			$adjuster = $app->Adjuster(-side =>'top', -widget => $nb)->pack(-after => $nbf, -fill => 'x');
			
		},
		-unselecttabcall => sub {
			my $t = shift;
# 			print "unselect $t\n";
# 			$nb->packForget;
# 			$app->update;
#			$adjuster->destroy;
# 			$app->update;
#			my $tf = $nb->Subwidget('TabFrame');
#			my $offset = ($tf->cget('-borderwidth') + $nb->cget('-borderwidth')) * 2;
#			$nb->GeometryRequest($nb->width, $nb->Subwidget('TabFrame')->height + $offset);
# 			$nb->pack(-expand => 1, -fill => 'both');
		},
# 		-borderwidth => 2,
# 		-tabside => 'left',
# 		-tabside => 'right',
# 		-tabside => 'bottom',
	)->pack(-expand => 1, -fill => 'both');
	for (1 .. 12) {
		my $num = $_;
		my $n = "page ";
		for (0 .. $num) { $n = $n . '*' }
		$n = "$n $num";
		my $p = $nb->addPage($n, -closebutton => 1);
		$p->Label(
			-width => 40 + $num, 
			-height => 18 + $num, 
			-text => $n, 
			-relief => 'groove',
			-borderwidth => 3,
		)->pack(-fill => 'y');
	}
	$nbf->pack(-expand => 1, -fill => 'both');
# 	my $mfr = $app->Frame(-relief => 'groove', -borderwidth => 4)->pack(-expand => 1, -fill => 'both');
#	$mfr->Label(-text => '------')->pack;
	$app->geometry('700x500+100+100');
}

@tests = (
	[sub {  return defined $nb }, '1', 'Can create']
);

starttesting;



