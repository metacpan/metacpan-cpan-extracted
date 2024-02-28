
use strict;
use warnings;

use Test::Tk;
$mwclass = 'Tk::AppWindow';

use Test::More tests => 4;
BEGIN { use_ok('Tk::AppWindow::Ext::ToolBar') };


createapp(
	-tooliconsize => 32,
	-toolitems => [
		[	'tool_button',		'New',		'poptest',		'document-new',	'Create a new document'], 
		[	'tool_button',		'Open',		'poptest',		'document-open',	'Open a document'],
		[	'tool_separator' ],
		[	'tool_button',		'Save',		'poptest',		'document-save',	'Save current document'], 
		[	'tool_button',		'Close',		'poptest',		'document-close',	'Close current document'], 
	],
	-extensions => [qw[ToolBar Art MenuBar ]],
);

my $ext;
if (defined $app) {
	$app->geometry('640x400+100+100') if defined $app;
	$ext = $app->extGet('ToolBar');
}

@tests = (
	[sub { return $ext->Name }, 'ToolBar', 'extension ToolBar loaded']
);

starttesting;

