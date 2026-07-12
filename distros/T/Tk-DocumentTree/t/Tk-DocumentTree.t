
use strict;
use warnings;
use Tk;

use Test::Tk;
use Test::More tests => 5;
BEGIN { use_ok('Tk::DocumentTree') };
use File::Spec;

# use Tk::GtkSettings;
# applyGtkSettings;

my @files = (
	't/Tk-DocumentTree.t',
	'Makefile.PL',
	'Changes',
	'lib/Tk/DocumentTree.pm',
	'Untitled',
);

createapp;

my $doctree;
if (defined $app) {
	$doctree = $app->DocumentTree(
	)->pack(-expand => 1, -fill => 'both');

	$app->Frame->pack;
	$app->Button(
		-text => 'Modified',
		-command => sub {
			my ($sel) = $doctree->selectionGet;
			print "$sel\n";
			$doctree->entryModified($sel);
		}
	)->pack(-side => 'left');
	$app->Button(
		-text => 'Saved',
		-command => sub {
			my ($sel) = $doctree->selectionGet;
			print "$sel\n";
			$doctree->entrySaved($sel);
		}
	)->pack(-side => 'left');
	$app->Button(
		-text => 'Collapse',
		-command => ['collapseAll', $doctree],
	)->pack(-side => 'left');
	$app->Button(
		-text => 'Expand',
		-command => ['expandAll', $doctree],
	)->pack(-side => 'left');
	my $sfile = File::Spec->rel2abs('lib/Tk/DocumentTree.pm');
	$app->Button(
		-text => 'Select',
		-command => ['entrySelect', $doctree, $sfile],
	)->pack(-side => 'left');
	$app->Button(
		-text => 'Refresh',
		-command => ['refresh', $doctree],
	)->pack(-side => 'left');
	$app->Button(
		-text => 'Delete',
		-command => ['entryDelete', $doctree, $sfile],
	)->pack(-side => 'left');
	$app->Button(
		-text => 'Add',
		-command => ['entryAdd', $doctree, $sfile],
	)->pack(-side => 'left');
	
}

@tests = (
	[sub { return defined $doctree }, '1', 'Can create'],
	[sub {
		for (@files) {
			my $name = $_;
#			print "adding $name\n";
			if (-e $name) {
				$name = File::Spec->rel2abs($_);
				$doctree->entryAdd($name);
			} else {
				$doctree->entryAdd($name);
			}
		}
		return 1 
	}, '1', 'Adding entries'],
#	[sub { pause(300); $doctree->refresh; return 1 }, '1', 'refresh'],
);

starttesting;





