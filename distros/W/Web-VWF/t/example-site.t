#!/usr/bin/env perl

# Renders the example site from the command line, as CLAUDE.md describes.  It
# runs from a copy in a temporary directory: root_dir in the environment wins
# over every cache directory, so running it in place would leave Berkeley DB
# files in example/.

use strict;
use warnings;

use Test::Most;

use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);

BEGIN {
	plan skip_all => 'needs File::Copy::Recursive' unless(eval { require File::Copy::Recursive; 1 });
}

my $root = File::Spec->catdir($Bin, File::Spec->updir());
my $site = File::Spec->catdir(tempdir(CLEANUP => 1), 'example');
File::Copy::Recursive::dircopy(File::Spec->catdir($root, 'example'), $site) or plan skip_all => "Cannot copy the example: $!";

sub render
{
	my @args = @_;

	local $ENV{'CONFIG_DIR'} = File::Spec->catdir($site, 'conf');
	local $ENV{'root_dir'} = $site;
	local $ENV{'LANG'} = 'en_GB.UTF-8';
	delete @ENV{qw(REMOTE_ADDR REQUEST_METHOD QUERY_STRING)};

	my $lib = File::Spec->catdir($root, 'lib');
	my $script = File::Spec->catfile($site, 'cgi-bin', 'page.fcgi');

	open(my $fh, '-|', $^X, "-I$lib", $script, @args) or return '';
	local $/;
	my $output = <$fh>;
	close($fh);

	return $output // '';
}

like(render('page=index'), qr/^Status: 200 OK/m, 'page=index is 200');
like(render('page=meta_data'), qr/^Status: 200 OK/m, 'page=meta_data is 200');
like(render(), qr/^Status: 300 Multiple Choices/m, 'no page is 300');
like(render('page=nosuch'), qr/^Status: 404 Not Found/m, 'an unknown page is 404');

done_testing();
