
use strict;
use warnings;
use lib './t/lib';

use Test::Tk;
$mwclass = 'Tk::AppWindow';
$delay = 1500;

use Test::More tests => 4;
BEGIN { 
	use_ok('Tk::AppWindow::Ext::Selector');
};

require TestTextManager;

createapp(
	-appname => 'Selector',
	-extensions => [qw[Art MenuBar ToolBar StatusBar MDI Selector]],
	-configfolder => 't/settings',
#	-icontheme => 'Oxygen',
	-contentmanagerclass => 'TestTextManager',
#	-icontheme => 'Bloom',
);

my $ext;
if (defined $app) {
	$app->geometry('640x400+100+100') if defined $app;
	$ext = $app->extGet('Selector');
}

@tests = (
	[sub { return $ext->Name }, 'Selector', 'extension Selector loaded']
);

starttesting;

