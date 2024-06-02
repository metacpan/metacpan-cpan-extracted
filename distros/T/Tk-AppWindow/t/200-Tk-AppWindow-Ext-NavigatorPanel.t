
use strict;
use warnings;
use lib './t/lib';

use Test::Tk;
$mwclass = 'Tk::AppWindow';
$delay = 1500;

use Test::More tests => 4;
BEGIN { 
	use_ok('Tk::AppWindow::Ext::ToolPanel');
};

require TestTextManager;

createapp(
	-appname => 'Navigator',
	-extensions => [qw[Art MenuBar ToolBar StatusBar MDI Navigator ToolPanel]],
	-configfolder => 't/settings',
	-contentmanagerclass => 'TestTextManager',
);

my $ext;
if (defined $app) {
	$app->geometry('640x400+100+100') if defined $app;
	$ext = $app->extGet('ToolPanel');
	$app->after(300, sub {
		my $page1 = $ext->addPage('Sample1', 'configure-toolbars', 'Sample page 1');
		$page1->Label(-text => 'Sample page 1')->pack(-expand => 1, -fill => 'both');
		my $page2 = $ext->addPage('Sample2', 'configure-toolbars', 'Sample page 2');
		$page2->Label(-text => '************ Sample page 2 ************')->pack(-expand => 1, -fill => 'both');
	});
}

@tests = (
	[sub { return $ext->Name }, 'ToolPanel', 'extension ToolPanel loaded']
);

starttesting;


