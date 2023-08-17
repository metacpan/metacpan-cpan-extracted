
use strict;
use warnings;
use Test::Tk;
use Tk;

use Test::More tests => 4;
BEGIN { use_ok('Tk::YANoteBook') };

$delay = 1500;

createapp;

my $nb;
if (defined $app) {
	my $frame = $app->Frame->pack(-expand => 1, -fill => 'both');
	$nb = $frame->YANoteBook(
		-relief => 'raised',
		-borderwidth => 2,
# 		-tabside => 'left',
# 		-tabside => 'right',
# 		-tabside => 'bottom',
	)->pack(-side => 'left', -fill => 'both', -expand => 1);
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
		)->pack();
	}
# 	$frame->Label(-width => 1, -height => 3)->pack(-side => 'left', -fill => 'x');
	$app->geometry('700x500+100+100');
}

@tests = (
	[sub {  return defined $nb }, '1', 'Can create']
);

starttesting;


