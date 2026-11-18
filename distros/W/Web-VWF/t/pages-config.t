#!/usr/bin/env perl

# The <display> setting: one <page> element for each page, with a name and a
# description.  Config::Abstraction hands a single <page> over as a hash and
# several as an array, and the old string of names is still accepted.

use strict;
use warnings;

use Test::Most;

use File::Spec;
use FindBin qw($Bin);

BEGIN {
	require lib;
	lib->import(File::Spec->catdir($Bin, File::Spec->updir(), 'lib'));
}

use Web::VWF;

sub pages
{
	return [Web::VWF->_config_pages({ display => shift })];
}

is_deeply(pages({ page => { name => 'states', description => 'About states' } }),
	[{ name => 'states', description => 'About states', directory => '' }], 'one page is a hash');

is_deeply(pages({ page => [{ name => 'a', description => 'A' }, { name => 'b' }] }),
	[{ name => 'a', description => 'A', directory => '' }, { name => 'b', description => '', directory => '' }],
	'several pages are an array, in order, and a missing description is empty');

is_deeply(pages({ page => [{ name => 'a' }, { name => 'a' }] }),
	[{ name => 'a', description => '', directory => '' }], 'a repeated page is dropped');

is_deeply(pages({ page => [{ description => 'no name' }, { name => '' }, { name => 'ok' }] }),
	[{ name => 'ok', description => '', directory => '' }], 'a page without a name is dropped');

is_deeply(pages('index, meta_data'),
	[{ name => 'index', description => '', directory => '' }, { name => 'meta_data', description => '', directory => '' }],
	'the old string form still works');

is_deeply(pages(undef), [], 'no setting gives no pages');

is_deeply([Web::VWF->_valid_pages({ display => { page => [{ name => 'a' }, { name => 'bad name' }] } })],
	['a'], 'only word-character names are valid pages');

is_deeply({ Web::VWF->_page_descriptions({ display => { page => [{ name => 'a', description => 'A' }, { name => 'b' }] } }) },
	{ a => 'A' }, 'only described pages have a description');

# <directory> says where to look for page modules when no <page> is listed
use File::Temp qw(tempdir);
my $dir = tempdir(CLEANUP => 1);
foreach my $name (qw(zebra apple captcha)) {
	open(my $fh, '>', File::Spec->catfile($dir, "$name.pm")) or die "$dir/$name.pm: $!";
	close($fh);
}
is_deeply([Web::VWF->_valid_pages({ display => { directory => $dir } })],
	['apple', 'zebra'], '<directory> alone: its modules, sorted, without captcha');
is_deeply([Web::VWF->_valid_pages({ display => { directory => $dir, page => { name => 'only' } } })],
	['only'], 'listed pages win over <directory>');

# A <directory> in a <page> beats the one in <display>, which beats @INC
is_deeply({ Web::VWF->_page_directories({ display => { directory => '/all', page => [
		{ name => 'a', directory => '/mine' }, { name => 'b' } ] } }, 'a', 'b') },
	{ a => '/mine', b => '/all' }, 'page directory, then pages directory');
is_deeply({ Web::VWF->_page_directories({ display => { page => [{ name => 'a', directory => '/mine' }, { name => 'b' }] } }, 'a', 'b') },
	{ a => '/mine' }, 'no pages directory: pages without their own are left to @INC');
is_deeply({ Web::VWF->_page_directories({ display => 'a, b' }, 'a', 'b') }, {}, 'the string form has none');

# <pages> is the name before the rename, and is still read
is_deeply([Web::VWF->_valid_pages({ pages => { page => { name => 'old' } } })], ['old'], '<pages> still works');
is_deeply([Web::VWF->_valid_pages({ display => { page => { name => 'new' } }, pages => { page => { name => 'old' } } })], ['new'], '<display> wins over <pages>');

done_testing();
