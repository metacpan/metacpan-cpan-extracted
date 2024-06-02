
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
		[	'tool_list'],
		[  'tool_button',		'Save',		'poptest',		'document-save',	'Save current document'], 
		[	'tool_button',		'Save as',		'poptest',		'document-save-as',	'Save current document under new name'], 
		[	'tool_separator' ],
		[	'tool_button',		'Save all',		'poptest',		'document-save',	'Save all modified documents'],
		[  'tool_list_end' ],
		[	'tool_list'],
		[  'tool_button',		'Save 2',		'poptest',		'document-save',	'Save current document'], 
		[	'tool_button',		'Save as 2',		'poptest',		'document-save-as',	'Save current document under new name'], 
		[	'tool_separator' ],
		[	'tool_button',		'Save all 2',		'poptest',		'document-save',	'Save all modified documents'],
		[  'tool_list_end' ],
		[	'tool_button',		'Close',		'poptest',		'document-close',	'Close current document'],
		[  'tool_widget',  'x',  'Entry', -width => 4 ],
	],
	-extensions => [qw[ToolBar StatusBar Art MenuBar ]],
);

my $ext;
if (defined $app) {
	$app->geometry('640x400+100+100') if defined $app;
	$ext = $app->extGet('ToolBar');
	$app->Button(
		-text => 'Reconfigure',
		-command => sub { $ext->ReConfigure },
	)->pack;
}

push @tests, (
	[sub { return $ext->Name }, 'ToolBar', 'extension ToolBar loaded']
);

starttesting;

