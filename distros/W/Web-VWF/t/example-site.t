#!/usr/bin/env perl

# Renders the example site from the command line, as CLAUDE.md describes.  It
# runs from a copy in a temporary directory: root_dir in the environment wins
# over every cache directory, so running it in place would leave Berkeley DB
# files in example/.

use strict;
use warnings;

use Test::Most;

use File::Spec;
use File::Copy ();
use File::Path ();
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
like(render('page=states'), qr/^Status: 200 OK/m, 'page=states is 200');
like(render('page=states'), qr{<td>NY</td><td>N\.Y\.</td><td>New York</td>}, 'page=states lists New York');
is(scalar(() = render('page=states') =~ /<tr><td>/g), 50, 'page=states lists all 50 states');
like(render(), qr/^Status: 300 Multiple Choices/m, 'no page is 300');
like(render(), qr{page=states - Displays information about the U\.S\. states}, 'the 300 describes each page');
like(render('page=nosuch'), qr/^Status: 404 Not Found/m, 'an unknown page is 404');

# A <directory> in the configuration is where a page's module is loaded from:
# move the states page out of example/lib and name where it went
{
	my $moved = File::Spec->catdir(tempdir(CLEANUP => 1), 'pages');
	my $from = File::Spec->catfile($site, 'lib', 'Web', 'VWF', 'Display', 'states.pm');
	File::Path::make_path($moved);
	File::Copy::move($from, File::Spec->catfile($moved, 'states.pm')) or die "Cannot move $from: $!";

	like(render('page=states'), qr/^Status: 404 Not Found/m, 'states is 404 when its module is not where it is looked for');

	my $conf = File::Spec->catfile($site, 'conf', 'default');
	open(my $in, '<', $conf) or die "$conf: $!";
	local $/;
	my $xml = <$in>;
	close($in);
	$xml =~ s{(<name>states</name>)}{$1<directory>$moved</directory>} or die 'no states page in the configuration';
	open(my $out, '>', $conf) or die "$conf: $!";
	print $out $xml;
	close($out);

	like(render('page=states'), qr/^Status: 200 OK/m, 'a page with its own <directory> loads from there');
}

# The same for a data module: move Web::VWF::Data::states out of example/lib and
# name where it went in its <database>.  A fresh copy of the site, as the one
# above has had its states page moved already.
{
	my $site2 = File::Spec->catdir(tempdir(CLEANUP => 1), 'example');
	File::Copy::Recursive::dircopy(File::Spec->catdir($root, 'example'), $site2) or die "Cannot copy the example: $!";
	$site = $site2;

	my $moved = File::Spec->catdir(tempdir(CLEANUP => 1), 'data-modules');
	my $from = File::Spec->catfile($site, 'lib', 'Web', 'VWF', 'Data', 'states.pm');
	File::Path::make_path($moved);
	File::Copy::move($from, File::Spec->catfile($moved, 'states.pm')) or die "Cannot move $from: $!";

	unlike(render('page=states'), qr/<td>NY<\/td>/, 'states has no data when its module is not where it is looked for');

	my $conf = File::Spec->catfile($site, 'conf', 'default');
	open(my $in, '<', $conf) or die "$conf: $!";
	my $xml = do { local $/; <$in> };
	close($in);
	$xml =~ s{(<name>states</name>)(\s*<description>List)}{$1<directory>$moved</directory>$2} or die 'no states database in the configuration';
	open(my $out, '>', $conf) or die "$conf: $!";
	print $out $xml;
	close($out);

	like(render('page=states'), qr{<td>NY</td><td>N\.Y\.</td><td>New York</td>}, 'a database with its own <directory> loads from there');
}

done_testing();
