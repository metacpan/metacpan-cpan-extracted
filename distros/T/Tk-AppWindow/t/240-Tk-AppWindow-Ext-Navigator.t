
use strict;
use warnings;
use lib './t/lib';

use Test::Tk;
$mwclass = 'Tk::AppWindow';
$delay = 1500;

use Test::More tests => 4;
BEGIN { 
	use_ok('Tk::AppWindow::Ext::Navigator');
};

require TestTextManager;

createapp(
	-appname => 'Navigator',
	-extensions => [qw[Art Balloon MenuBar ToolBar StatusBar MDI Navigator]],
	-configfolder => 't/settings',
	-contentmanagerclass => 'TestTextManager',
#	-icontheme => 'Bloom',
);

my $ext;
if (defined $app) {
	$app->geometry('640x400+100+100') if defined $app;
	$ext = $app->extGet('Navigator');
}

@tests = (
	[sub { return $ext->Name }, 'Navigator', 'extension Navigator loaded']
);

starttesting;

