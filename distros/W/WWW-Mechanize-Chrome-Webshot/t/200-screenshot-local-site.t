#!/usr/bin/env perl

###################################################################
#### NOTE env-var PERL_TEST_TEMPDIR_TINY_NOCLEANUP=1 will stop erasing tmp files
###################################################################

use strict;
use warnings;

use utf8; # we have utf8 strings here

use Test::More;
use Test::More::UTF8;
use Test::TempDir::Tiny;
use Cwd;
use File::Basename;
use FindBin;

use lib ($FindBin::Bin, 'blib/lib');

use WWW::Mechanize::Chrome::Webshot;

our $VERSION = '0.05';

my $curdir = Cwd::abs_path($FindBin::Bin);

# if for debug you change this make sure that it has path in it e.g. ./xyz
my $tmpdir = tempdir(); # will be erased unless a BAIL_OUT or env var set
ok(-d $tmpdir, "tmpdir exists $tmpdir") or BAIL_OUT;

my $configfile = File::Spec->catfile($curdir, '..', 'config', 'myapp.conf');
ok(-f $configfile, "config file exists ($configfile).") or BAIL_OUT;

my $VERBOSITY = 0;
my $CLEANUP = (exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && ($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0)) ? 1 : 0;

# localfile
my $URL = 'file://'.${curdir}.'/t-data/html-site/content.html';

my $cparams = {
	'configfile' => $configfile,
#	'verbosity' => $VERBOSITY, # use config's
	'cleanup' => $CLEANUP,
	'launch-mech-on-demand' => 1,
	'settle-time' => 2, # it's a local site!
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

