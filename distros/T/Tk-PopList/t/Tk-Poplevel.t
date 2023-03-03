
use strict;
use warnings;

use Test::More tests => 4;
BEGIN { use_ok('Tk::Poplevel') };

use Test::Tk;
require Tk::ROText;

createapp(
	-width => 300,
	-height => 200,
);

my $poplevel;
if (defined $app) {
	my $b = $app->Button(
		-command => sub  { $poplevel->popUp },
		-text => 'Popper',
	)->pack;
	my $frame = $app->Frame(
		-width => 300,
		-height => 200,
	)->pack;
	$poplevel = $frame->Poplevel(
		-confine => 0,
		-widget => $b,
	);
	$poplevel->ROText(
   )->pack;
}

@tests = (
	[sub { return defined $poplevel }, 1, 'Created Poplevel'],
);
starttesting;


