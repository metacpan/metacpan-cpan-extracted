
use strict;
use warnings;
use lib './t/lib';
use Test::More tests => 21;
use Test::Tk;
$mwclass = 'Alternative::NameSpace';
$delay = 1500;

BEGIN { 
	use_ok('Tk::AppWindow::Ext::Plugins');
	use_ok('Tk::AppWindow::PluginsForm');
	use_ok('Alternative::NameSpace');
	use_ok('Alternative::NameSpace::Plugins::Test');
	use_ok('Alternative::NameSpace::Plugins::TestJobs');
};

require TestTextManager;

createapp(
	-commands => [plusser => [sub {
		my $v = 2;
		return $v + shift if @_;
		return $v;
	}]],
	-configfolder => 't/settings',
	-toolitems => [
		[	'tool_button',		'Placeholder',		'poptest',	'document-open',	'Open a document'], 
		[	'tool_separator'], 
	],
	-namespace => 'Alternative::NameSpace',
	-plugins => ['Test', 'TestJobs'],
	-preconfig => [
		-somecolor => ['PASSIVE', undef, undef, '#34A767'],
	],
	-useroptions => [
		'*page' => 'Color',
		-somecolor => ['color', 'Color'],
	],
);

my $ext;
my $daem;
if (defined $app) {
	$app->geometry('640x400+100+100') if defined $app;
	$ext = $app->extGet('Plugins');
	$daem = $app->extGet('Daemons');
	
	$app->Button(
		-width => 30,
		-text => 'Load',
		-command => sub {
			$ext->plugLoad('Test');
		}
	)->pack(-fill => 'x', -padx => 2, -pady => 2);
	$app->Button(
		-text => 'Unload',
		-command => ['plugUnload', $ext, 'Test'],
	)->pack(-fill => 'x', -padx => 2, -pady => 2);
}

@tests = (
	[sub { return $ext->Name }, 'Plugins', 'extension Plugins loaded'],
	[sub { return $ext->plugGet('Test')->Name }, 'Test', 'plugin Test loaded',],
	[sub { return $app->cmdExecute('plusser') }, 4, 'Hook loaded'],
	[sub { 
		$ext->plugGet('Test')->Quitter(0); 
		$app->cmdExecute('quit'); 
		return 1 
	}, 1, 'still running'],
	[sub {
		$ext->plugUnload('Test');
		return $ext->plugGet('Test')->Name; 
	}, 'Test', 'plugin Test can not unload'],
	[sub { 
		$ext->plugGet('Test')->Quitter(1); 
		return 1
	}, 1, 'now can quit'],
	[sub {
		$ext->plugUnload('Test');
		return $ext->plugGet('Test'); 
	}, undef, 'plugin Test unloaded'],
	[sub { return $app->cmdExecute('plusser') }, 2, 'Hook unloaded'],
	[sub { return $ext->plugGet('TestJobs')->Name }, 'TestJobs', 'plugin TestJobs loaded',],
	[sub { 
		return $ext->plugGet('TestJobs')->jobExists('jobtest'); 
	}, 1, 'job jobtest exists'],
	[sub { 
		my @l = $ext->plugGet('TestJobs')->jobList;
		return \@l
	}, [ 'jobtest' ], 'jobList'],
	[sub { 
		return $daem->jobExists('jobtestTestJobs'); 
	}, 1, 'job jobtestTestJobs exists'],
	[sub {
		$ext->plugUnload('TestJobs');
		return $ext->plugGet('TestJobs'); 
	}, undef, 'plugin TestJobs unloaded'],
	[sub { 
		return $daem->jobExists('jobtestTestJobs'); 
	}, '', 'job jobtestTestJobs terminated'],
);

starttesting;

unlink 't/settings/plugins';




