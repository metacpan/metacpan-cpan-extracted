#!/usr/bin/env perl

###################################################################
#### NOTE env-var PERL_TEST_TEMPDIR_TINY_NOCLEANUP=1 will stop erasing tmp files
###################################################################

use strict;
use warnings;

use utf8; # we have unicode strings in here

use Test::More;
use Test::More::UTF8;
use Test::TempDir::Tiny;
use Cwd;
use File::Basename;
use FindBin;
use File::Spec;
use Image::ExifTool qw(:Public);
use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

use lib ($FindBin::Bin, 'blib/lib');

use WWW::Mechanize::Chrome::Webshot;

our $VERSION = '0.02';

my $VERBOSITY = 0; # we need verbosity of 10 (max), so this is not used
my $CLEANUP = (exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && ($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0)) ? 1 : 0;

my $curdir = Cwd::abs_path($FindBin::Bin);

# if for debug you change this make sure that it has path in it e.g. ./xyz
my $tmpdir = tempdir(); # will be erased unless a BAIL_OUT or env var set
ok(-d $tmpdir, "tmpdir exists $tmpdir") or BAIL_OUT;

my $configfile = File::Spec->catfile($curdir, '..', 'config', 'myapp.conf');
ok(-f $configfile, "config file exists ($configfile).") or BAIL_OUT;

# a localsite
my $URL = 'file://'.${curdir}.'/t-data/html-site/content.html';

my $cparams = {
	'configfile' => $configfile,
	'launch-mech-on-demand' => 0,
	'settle-time' => 2,
#	'verbosity' => 2, # use config's
	'cleanup' => $CLEANUP,
	'remove-dom-elements' => [
		{
			'element-class' => 'div-class-1',
			'element-tag' => 'div',
			'&&' => 1
		},
		# undef, # with an undef you stop here and forget the rest...
		{
			'element-id' => 'div-id-2',
			'element-tag' => 'div',
			'&&' => 1
		},
		{
			'element-id' => 'span-id-1',
			'element-tag' => 'span',
			'&&' => 1
		},
	],
};
my $shooter = WWW::Mechanize::Chrome::Webshot->new($cparams);
ok(defined $shooter, 'WWW::Mechanize::Chrome::Webshot->new() : called') or BAIL_OUT("Call to ".'WWW::Mechanize::Chrome::Webshot->new()'." has failed.");

# go to blank tab (it will also settle for a while
$shooter->blank_browser();

my $tmpfile = File::Spec->catfile($tmpdir, 'out.png');

my $shoot_params = {
	'output-filename' => $tmpfile,
	'url' => $URL,
	'exif' => {
		'url' => $URL,
		'crap' => '123.1123:121.32111',
		# can not have unicode keys it seems(?)
		'unicode' => 'ελληνικά και agglika',
	},
};
$shooter->shoot($shoot_params);
ok(-s $tmpfile, "$tmpfile contains the screenshot") or BAIL_OUT("no screenshot was created, something seriously wrong.");

# check we have the exif tags
my $retc = WWW::Mechanize::Chrome::Webshot::_check_if_exif_tags_exist_in_image($tmpfile, $shoot_params->{'exif'});
ok(defined($retc), 'WWW::Mechanize::Chrome::Webshot::_check_if_exif_tags_exist_in_image()'." : called and got defined result.") or BAIL_OUT;
for my $tn (keys %{ $shoot_params->{'exif'} }){
	ok(exists($retc->{$tn}), 'WWW::Mechanize::Chrome::Webshot::_check_if_exif_tags_exist_in_image()'." : called and result contains tagname '${tn}'.") or BAIL_OUT;
	is($retc->{$tn}, 1, 'WWW::Mechanize::Chrome::Webshot::_check_if_exif_tags_exist_in_image()'." : called and result contains tagname '${tn}' and it exists in the image with correct value.") or BAIL_OUT;
}

diag "temp dir: $tmpdir ..." if $CLEANUP;

# END
done_testing();
