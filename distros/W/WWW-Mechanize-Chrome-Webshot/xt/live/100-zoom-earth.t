#!/usr/bin/env perl

###################################################################
#### NOTE env-var PERL_TEST_TEMPDIR_TINY_NOCLEANUP=1 will stop erasing tmp files
###################################################################

use strict;
use warnings;

use utf8; # we use unicode strings in here

use Test::More;
use Test::More::UTF8;
use Test::TempDir::Tiny;
use Cwd;
use File::Basename;
use FindBin;

use lib ($FindBin::Bin, 'blib/lib');

use WWW::Mechanize::Chrome::Webshot;

our $VERSION = '0.04';

my $VERBOSITY = 10; # we need verbosity of 10 (max), so this is not used
my $CLEANUP = (exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && ($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0)) ? 1 : 0;

my $curdir = $FindBin::Bin;

# if for debug you change this make sure that it has path in it e.g. ./xyz
my $tmpdir = tempdir(); # will be erased unless a BAIL_OUT or env var set
ok(-d $tmpdir, "tmpdir exists $tmpdir") or BAIL_OUT;

my $configfile = File::Spec->catfile($curdir, '..', '..', 'config', 'myapp.conf');
ok(-f $configfile, "config file exists ($configfile).") or BAIL_OUT;

# sicily
my $URL = 'https://zoom.earth/#38.093577,13.444609,17z,sat';

my $cparams = {
	'configfile' => $configfile,
	'settle-time' => 10,
#	'verbosity' => 2, # use config's 
	'cleanup' => $CLEANUP,
	# WARNING: the tests may fail because we are trying to remove DOM elements
	# in an HTML last inspected in Aug-2021. HTML does change.
	# if tests fail, download the URL above or inspect it using Firefox's Dev Tools.
	# there is verbosity level, above too.
	# when tests succeed, you will probably need to inspect the output
	# PNG (comment unlink below) and see if the shot is to your liking
	# or whether it needs more DOM elements to be removed, which you
	# may add below. -- BLIAKO
	'remove-dom-elements' => [
		{
			'element-class' => 'share',
			'element-tag' => 'button',
			'&&' => 1
		},
		# undef, # with an undef you stop here and forget the rest...
		{
			'element-class' => 'select-satellite',
			'element-tag' => 'nav',
			'&&' => 1
		},
		{
			'element-class' => 'hit',
			'element-tag' => 'div',
			'&&' => 1
		},
		{
			'element-class' => ['panel', 'clock'],
			'element-tag' => 'div',
			'&&' => 1
		},
		{
			'element-class' => ['panel', 'title'],
			'element-tag' => 'nav',
			'&&' => 1
		},
		{
			'element-class' => 'search',
			'element-tag' => 'button',
			'&&' => 1
		},
		{
			'element-class' => 'settings',
			'element-tag' => 'button',
			'&&' => 1
		},
		{
			'element-class' => 'about',
			'element-tag' => 'button',
			'&&' => 1
		},
		{
			'element-class' => 'share',
			'element-tag' => 'button',
			'&&' => 1
		},
		{
			'element-class' => 'geolocation',
			'element-tag' => 'button',
			'&&' => 1
		},
		{
			'element-class' => ['group', 'measure'],
			'element-tag' => 'div',
			'&&' => 1
		},
		{
			'element-class' => ['panel', 'welcome', 'location'],
			'element-tag' => 'aside',
			'&&' => 1
		},

#		{
#			'element-class' => ['panel', 'overlays'],
#			'element-tag' => 'nav',
#			'&&' => 1
#		},
#		{
#			'element-class' => ['group', 'overlays'],
#			'element-tag' => 'div',
#			'&&' => 1
#		},
#		{
#			'element-class' => ['group', 'zoom'],
#			'element-tag' => 'div',
#			'&&' => 1
#		},
	],
};
my $shooter = WWW::Mechanize::Chrome::Webshot->new($cparams);
ok(defined $shooter, 'WWW::Mechanize::Chrome::Webshot->new() : called') or BAIL_OUT("Call to ".'WWW::Mechanize::Chrome::Webshot->new()'." has failed.");

my $tmpfile = File::Spec->catfile($tmpdir, 'out.png');

my $metadata = {
	'Aa' => 'ellinika και αγγλικά',
	'Bb' => 'ελληνικά',
	'Cc' => 'agglika',
};
my $r = $shooter->shoot({
	'output-filename' => $tmpfile,
	'url' => $URL,
	'exif' => $metadata
});
is($r, 1, 'shoot()'." : called and got good result.") or BAIL_OUT;
ok(-f $tmpfile, "$tmpfile contains the screenshot") or BAIL_OUT("no screenshot was created, something seriously wrong.");
ok(! -z $tmpfile, "$tmpfile contains some bytes") or BAIL_OUT("no data in screenshot file, something seriously wrong.");

# verify output image has exif metadata
my $rr = WWW::Mechanize::Chrome::Webshot::_check_if_exif_tags_exist_in_image(
	$tmpfile,
	$metadata,
	$shooter->log,
);
ok(defined $rr, 'WWW::Mechanize::Chrome::Webshot::_check_if_exif_tags_exist_in_image()'." : called and got some result back") or BAIL_OUT;
# returns a hash with tags as keys and each key having a value:
# 0 : missing
# 1 : exists and has correct value
# 2 : exists but has incorrect value
is(ref($rr), 'HASH', 'WWW::Mechanize::Chrome::Webshot::_check_if_exif_tags_exist_in_image()'." : called and return value is a HASHref.") or BAIL_OUT("no return value is of type '".ref($rr)."'.");
for my $k (sort keys %$rr){
	my $v = $rr->{$k};
	is($v, 1, 'WWW::Mechanize::Chrome::Webshot::_check_if_exif_tags_exist_in_image()'." : called and return hash key '$k' has value '$v' as expected (1).") or BAIL_OUT("no, key '$k' has value '$v' (check the implementation of 'WWW::Mechanize::Chrome::Webshot::_check_if_exif_tags_exist_in_image' to see what does that mean.");
}

diag "temp dir: $tmpdir ..." if $CLEANUP;

# END
done_testing();
