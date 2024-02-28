
use strict;
use warnings;
use lib './t/lib';

use Test::Tk;
$mwclass = 'Tk::AppWindow';

use Test::More tests => 4;
BEGIN { use_ok('Tk::AppWindow::Ext::SDI') };

$delay = 1500;
require TestTextManager;
my $settingsfolder = 't/settings';


createapp(
	-configfolder => $settingsfolder,
	-extensions => [qw[Art MenuBar ToolBar SDI]],
	-contentmanagerclass => 'TestTextManager',
);

my $ext;
if (defined $app) {
	$app->geometry('640x400+100+100') if defined $app;
	$ext = $app->extGet('SDI');
}

@tests = (
	[sub { return $ext->Name }, 'SDI', 'extension SDI loaded']
);

starttesting;


