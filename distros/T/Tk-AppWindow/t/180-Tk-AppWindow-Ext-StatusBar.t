
use strict;
use warnings;

use Test::Tk;
$mwclass = 'Tk::AppWindow';

use Test::More tests => 12;
BEGIN { 
	use_ok('Tk::AppWindow::Ext::StatusBar::SBaseItem');
	use_ok('Tk::AppWindow::Ext::StatusBar::SImageItem');
	use_ok('Tk::AppWindow::Ext::StatusBar::SMessageItem');
	use_ok('Tk::AppWindow::Ext::StatusBar::SProgressItem');
	use_ok('Tk::AppWindow::Ext::StatusBar::STextItem');
	use_ok('Tk::AppWindow::Ext::StatusBar');
};


createapp(
	-extensions => [qw[ Art MenuBar StatusBar ]],
);

my $ext;
if (defined $app) {
	$app->geometry('640x400+100+100') if defined $app;
	$ext = $app->extGet('StatusBar');
	pause(200);

	my @padding = (-side => 'left', -padx => 10, -pady => 10);
	my $ws = $app->WorkSpace;
	my $black = $ws->Button(
		-text => 'Log message',
		-command => sub { $app->log('Oh, gosh, I hope I don\'t fall in love today') },
	)->pack(@padding);

	my $red = $ws->Button(
		-text => 'Log error',
		-command => sub { $app->logError('Oh, gosh, I hope I don\'t fall in love today') },
	)->pack(@padding);

	my $blue = $ws->Button(
		-text => 'Log warning',
		-command => sub { $app->logWarning('Oh, gosh, I hope I don\'t fall in love today') },
	)->pack(@padding);

	my $boole = 1;
	$ext->AddImageItem('image',
		-valueimages => {
			0 => 'edit-copy',
			1 => 'edit-paste',
		},
		-label => 'Image',
		-updatecommand => sub {
			if ($boole) { $boole = 0 } else { $boole = 1 }
			return $boole
		}
	);

	my $num = 0;
	$ext->AddTextItem('text',
		-label => 'Text',
		-updatecommand => sub {
			my $old = $num;
			$num++;
			if ($num eq 10) { $num = 0 }
			return $old
		}
	);

	my $prog = 0;
	$ext->AddProgressItem('progress',
		-label => 'Progress',
		-updatecommand => sub {
			my $old = $prog;
			$prog = $prog + 10;
			if ($prog eq 110) { $prog = 0 }
			return $old
		}
	);
}

@tests = (
	[sub { return $ext->Name eq 'StatusBar' }, 1, 'plugin StatusBar loaded'],
	[sub { return ref $ext->{MI} }, 'Tk::AppWindow::Ext::StatusBar::SMessageItem', 'message item loaded'],
	[sub { return ref $ext->Item('image') }, 'Tk::AppWindow::Ext::StatusBar::SImageItem', 'image item loaded'],
	[sub { return ref $ext->Item('text') }, 'Tk::AppWindow::Ext::StatusBar::STextItem', 'text item loaded'],
# 	[sub { return ref $ext->Item('progress') }, 'Tk::AppWindow::Ext::StatusBar::SProgressItem', 'progress item loaded'],
);

starttesting;


