
use strict;
use warnings;
use lib './t/lib';

use Test::Tk;
$mwclass = 'Tk::AppWindow';
$delay = 500;

use Test::More tests => 9;
BEGIN { 
	use_ok('Tk::AppWindow::Ext::MDI');
};

require TestTextManager;

createapp(
	-extensions => [qw[Art MenuBar MDI ToolBar]],
	-configfolder => 't/settings',
	-contentmanagerclass => 'TestTextManager',
);

my $ext;
if (defined $app) {
	$app->geometry('640x400+100+100') if defined $app;
	$ext = $app->extGet('MDI');
	my $disabled = 'Select enabled';
	$app->Subwidget('TOP')->Button(
		-textvariable => \$disabled,
		-command => sub {
			if ($ext->selectDisabled) {
				$ext->selectDisabled(0);
				$disabled = 'Select enabled';
			} else {
				$ext->selectDisabled(1);
				$disabled = 'Select disabled';
			}
		}
	)->pack(-side => 'right', -padx => 2);
}

testaccessors($ext, 'docForceClose', 'docSelected', 'historyDisabled', 'selectDisabled');
push @tests,
	[sub { return defined $ext }, 1, 'Extension defined'],
	[sub { return $ext->Name  }, 'MDI', 'Extension MDI loaded'];

# $app->cmdExecute('doc_new');
starttesting;




