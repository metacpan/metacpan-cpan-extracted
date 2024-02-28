
use strict;
use warnings;

use Test::Tk;
$mwclass = 'Tk::AppWindow';
use Test::More tests => 7;
BEGIN { use_ok('Tk::AppWindow::Ext::Keyboard') };


createapp(
	-extensions => [qw[Keyboard]],
	-commands => [
		'on_press_o' => [sub { print "o-key pressed\n" }],
	],
	-keyboardbindings => [
		on_press_o => 'o'
	],
);

my $ext;
if (defined $app) {
	$app->geometry('640x400+100+100') if defined $app;
	$ext = $app->extGet('Keyboard');
}

@tests = (
	[sub { return $ext->Name }, 'Keyboard', 'extension Keyboard loaded'],
	[sub { return $ext->Convert2Tk('CTRL+SHIFT+G') }, 'Control-G', 'Conversion CTRL+SHIFT+G'],
	[sub { return $ext->Convert2Tk('CTRL+G') }, 'Control-g', 'Conversion CTRL+G'],
	[sub { return $ext->Convert2Tk('SHIFT+F10') }, 'Shift-F10', 'Conversion SHIFT+F10'],
);

starttesting;


