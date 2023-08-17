
use strict;
use warnings;
use Test::Tk;;
use Tk;

use Test::More tests => 5;
BEGIN { use_ok('Tk::YADialog') };


createapp;
$delay = 400;

my $dialog;
if (defined $app) {
	$dialog = $app->YADialog(
		-buttons => ['Close'],
		-defaultbutton => 'Close',
	);
	$dialog->Label(-text => "This is a dialog")->pack(-fill => 'x',-padx => 10, -pady => 10);
}

@tests = (
	[sub { return defined $dialog }, 1, 'Tk::Dialog created'],
	[sub {  
		if ($show) {
			return $dialog->Show(-popover => $app)
		} else {
			return 'Close'
		}
	}, 'Close', 'pressing a button']
);

starttesting;



