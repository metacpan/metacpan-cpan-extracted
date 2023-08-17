
use strict;
use warnings;
use Test::Tk;;
use Tk;
require Tk::Pixmap;

use Test::More tests => 5;
BEGIN { use_ok('Tk::YAMessage') };

createapp;
$delay = 400;

my $dialog;
if (defined $app) {
	$dialog = $app->YAMessage(
		-text => "This is a loong looooong \nloooooong\n long longer\n longest message!",
		-image => $app->Pixmap(-file => "flower.xpm"),
		-defaultbutton => 'Ok',
	);
}

@tests = (
	[sub { return defined $dialog }, 1, 'Tk::Dialog created'],
	[sub {  
		if ($show) {
			return $dialog->Show(-popover => $app);
		} else {
			return 'Ok'
		}
	}, 'Ok', 'pressing a button']
);

starttesting;

