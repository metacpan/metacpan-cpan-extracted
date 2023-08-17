
use strict;
use warnings;
use Tk;

use Test::Tk;
use Test::More tests => 4;
BEGIN { use_ok('Tk::DocumentTree') };
use File::Spec;

# use Tk::GtkSettings;
# applyGtkSettings;

my @files = (
	'Untitled',
	't/Tk-DocumentTree.t',
	'Makefile.PL',
	'Changes',
	'lib/Tk/DocumentTree.pm',
);

createapp;

my $doctree;
if (defined $app) {
	$doctree = $app->DocumentTree(
	)->pack(-expand => 1, -fill => 'both');

	for (@files) {
		my $name = $_;
		if (-e $name) {
			$name = File::Spec->rel2abs($_);
			$doctree->entryAdd($name);
		} else {
			$doctree->entryAdd($name);
		}
	}
}

@tests = (
	[sub {  return defined $doctree }, '1', 'Can create']
);

starttesting;


