
use strict;
use warnings;
use Test::Tk;;
use Tk;

use Test::More tests => 7;
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
		$dialog->configure(-nowithdraw => 1);
		my $pressed;
		$app->after(50, sub { 
			$dialog->Pressed('stop');
			$pressed = $dialog->get;
		});
		$app->after(100, sub { 
			$dialog->configure(-nowithdraw => 0);
			$dialog->Pressed('stop') 
		});
		$dialog->show(-popover => $app);
		return $pressed;
	}, '', 'no pop down'],
	[sub {
#		pause(2000);
		$app->after(100, sub { $dialog->Pressed('stop') });
		return $dialog->show(-popover => $app);
	}, 'stop', 'popped down'],
	[sub {  
#		pause(2000);
		if ($show) {
			return $dialog->Show(-popover => $app)
		} else {
			return 'Close'
		}
	}, 'Close', 'pressing a button'],
);

starttesting;



