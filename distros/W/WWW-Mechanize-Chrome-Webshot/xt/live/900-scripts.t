#!/usr/bin/env perl

###################################################################
#### NOTE env-var PERL_TEST_TEMPDIR_TINY_NOCLEANUP=1 will stop erasing tmp files
###################################################################

use strict;
use warnings;

use utf8;

use Test::More;
use Test2::Plugin::UTF8;
use Test::Script;
use Test::TempDir::Tiny;
use File::Spec;
use Mojo::Log;
use FindBin;
use Cwd;
use File::Basename;
use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

use WWW::Mechanize::Chrome::Webshot qw/_check_if_exif_tags_exist_in_image/;

our $VERSION = '0.05';

my $VERBOSITY = 0; # we need verbosity of 10 (max), so this is not used
my $CLEANUP = (exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && ($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0)) ? 1 : 0;

my $curdir = $FindBin::Bin;

my $log = Mojo::Log->new;

# if for debug you change this make sure that it has path in it e.g. ./xyz
my $tmpdir = tempdir(); # will be erased unless a BAIL_OUT or env var set
ok(-d $tmpdir, "tmpdir exists $tmpdir") or BAIL_OUT;

my $configfile = File::Spec->catfile($curdir, '..', '..', 'config', 'myapp.conf');
ok(-f $configfile, "config file exists ($configfile).") or BAIL_OUT;

my $FAILURE_REGEX = qr/(?:\: error,)|(?:Usage)/;

my $URL = 'file://'.${curdir}.'/../../t/t-data/html-site/content.html';

my ($DOM_JSON_1item_oneliner_success, $DOM_JSON_1item_oneliner_fail,
    $DOM_JSON_4item_oneliner_fail, $DOM_JSON_4item_oneliner_success,
    $FH, $dfile
);

my $outfile = File::Spec->catfile($tmpdir, 'testout.png');

my $exif = {
	'url' => $URL,
	'bojo' => 'clown',
	# can not have unicode keys it seems(?)
	'unicode' => 'ελληνικά και agglika',
};
my @exif_cmdline; for my $tn (keys %$exif){ push @exif_cmdline, '--exif', $tn, $exif->{$tn} }

$dfile = File::Spec->catfile($curdir, '..', '..', 't', 't-data', 'json-dom-selectors', 'local-site', '1item-oneliner-success.json');
ok(open($FH, '<:encoding(UTF-8)', $dfile), "file '$dfile' opened for reading DOM selectors as JSON.") or BAIL_OUT("no, it failed: $!");
{ local $/ = undef; $DOM_JSON_1item_oneliner_success = <$FH> } close $FH; $DOM_JSON_1item_oneliner_success =~ s/\n+$//;

$dfile = File::Spec->catfile($curdir, '..', '..', 't', 't-data', 'json-dom-selectors', 'local-site', '1item-oneliner-fail.json');
ok(open($FH, '<:encoding(UTF-8)', $dfile), "file '$dfile' opened for reading DOM selectors as JSON.") or BAIL_OUT("no, it failed: $!");
{ local $/ = undef; $DOM_JSON_1item_oneliner_fail = <$FH> } close $FH; $DOM_JSON_1item_oneliner_fail =~ s/\n+$//;

$dfile = File::Spec->catfile($curdir, '..', '..', 't', 't-data', 'json-dom-selectors', 'local-site', '4item-oneliner-success.json');
ok(open($FH, '<:encoding(UTF-8)', $dfile), "file '$dfile' opened for reading DOM selectors as JSON.") or BAIL_OUT("no, it failed: $!");
{ local $/ = undef; $DOM_JSON_4item_oneliner_success = <$FH> } close $FH; $DOM_JSON_4item_oneliner_success =~ s/\n+$//;

$dfile = File::Spec->catfile($curdir, '..', '..', 't', 't-data', 'json-dom-selectors', 'local-site', '4item-oneliner-fail.json');
ok(open($FH, '<:encoding(UTF-8)', $dfile), "file '$dfile' opened for reading DOM selectors as JSON.") or BAIL_OUT("no, it failed: $!");
{ local $/ = undef; $DOM_JSON_4item_oneliner_fail = <$FH> } close $FH; $DOM_JSON_4item_oneliner_fail =~ s/\n+$//;

my @TESTS = (
	# test the scripts (the keys) with the scripts contained in the values
	# script-filename	  CLI-params-for-success    CLI-params-for-failure
	# dom from the CLI
	[
		['script/www-mechanize-webshot.pl', '--configfile', $configfile, @exif_cmdline, '--url', $URL, '--remove-dom-elements', $DOM_JSON_1item_oneliner_success, '--output-filename', $outfile],
		['script/www-mechanize-webshot.pl', '--configfile', $configfile, @exif_cmdline, '--url', $URL, '--remove-dom-elements', $DOM_JSON_1item_oneliner_fail, '--output-filename', $outfile],
	],
	[
		['script/www-mechanize-webshot.pl', '--configfile', $configfile, @exif_cmdline, '--url', $URL, '--remove-dom-elements', $DOM_JSON_4item_oneliner_success, '--output-filename', $outfile],
		['script/www-mechanize-webshot.pl', '--configfile', $configfile, @exif_cmdline, '--url', $URL, '--remove-dom-elements', $DOM_JSON_4item_oneliner_fail, '--output-filename', $outfile],
	],
	# dom read from file oneline
	[
		['script/www-mechanize-webshot.pl', '--configfile', $configfile, @exif_cmdline, '--url', $URL, '--remove-dom-elements-file', File::Spec->catfile($curdir, '..', '..', 't', 't-data', 'json-dom-selectors', 'local-site', '1item-success.json'), '--output-filename', $outfile],
		['script/www-mechanize-webshot.pl', '--configfile', $configfile, @exif_cmdline, '--url', $URL, '--remove-dom-elements-file', File::Spec->catfile($curdir, '..', '..', 't', 't-data', 'json-dom-selectors', 'local-site', '1item-fail.json'), '--output-filename', $outfile],
	],
	[
		['script/www-mechanize-webshot.pl', '--configfile', $configfile, @exif_cmdline, '--url', $URL, '--remove-dom-elements-file', File::Spec->catfile($curdir, '..', '..', 't', 't-data', 'json-dom-selectors', 'local-site', '4item-success.json'), '--output-filename', $outfile],
		['script/www-mechanize-webshot.pl', '--configfile', $configfile, @exif_cmdline, '--url', $URL, '--remove-dom-elements-file', File::Spec->catfile($curdir, '..', '..', 't', 't-data', 'json-dom-selectors', 'local-site', '4item-fail.json'), '--output-filename', $outfile],
	],
	# dom read from file multiline
	[
		['script/www-mechanize-webshot.pl', '--configfile', $configfile, @exif_cmdline, '--url', $URL, '--remove-dom-elements-file', File::Spec->catfile($curdir, '..', '..', 't', 't-data', 'json-dom-selectors', 'local-site', '1item-success.json'), '--output-filename', $outfile],
		['script/www-mechanize-webshot.pl', '--configfile', $configfile, @exif_cmdline, '--url', $URL, '--remove-dom-elements-file', File::Spec->catfile($curdir, '..', '..', 't', 't-data', 'json-dom-selectors', 'local-site', '1item-fail.json'), '--output-filename', $outfile],
	],
	[
		['script/www-mechanize-webshot.pl', '--configfile', $configfile, @exif_cmdline, '--url', $URL, '--remove-dom-elements-file', File::Spec->catfile($curdir, '..', '..', 't', 't-data', 'json-dom-selectors', 'local-site', '4item-success.json'), '--output-filename', $outfile],
		['script/www-mechanize-webshot.pl', '--configfile', $configfile, @exif_cmdline, '--url', $URL, '--remove-dom-elements-file', File::Spec->catfile($curdir, '..', '..', 't', 't-data', 'json-dom-selectors', 'local-site', '4item-fail.json'), '--output-filename', $outfile],
	],
);

#### nothing to change below
my $num_tests = 0;
 
my $dirname = File::Basename::dirname(__FILE__);
for my $atest (@TESTS){
	my $cmdline = $atest->[0];
	my $ascriptname = $cmdline->[0];
	my ($stdout, $stderr);
	script_compiles($ascriptname) or print "script ($ascriptname) does not compile.\n"; $num_tests++;
	script_runs($cmdline, {
		'stdout' => \$stdout,
		'stderr' => \$stderr,
	}, 'test:'.$ascriptname) or print "command failed: @$cmdline\n"; $num_tests++;
	ok(-f $outfile, "script ($ascriptname) run and output file '$outfile' exists.");
	# check it has the exif tags we asked to be inserted
	my $retc = WWW::Mechanize::Chrome::Webshot::_check_if_exif_tags_exist_in_image(
		$outfile,
		$exif,
		$log,
	);
	ok(defined($retc), 'WWW::Mechanize::Chrome::Webshot::_check_if_exif_tags_exist_in_image()'." : called and got defined result.") or BAIL_OUT;
	for my $tn (keys %$exif){
		ok(exists($retc->{$tn}), 'WWW::Mechanize::Chrome::Webshot::_check_if_exif_tags_exist_in_image()'." : called and result contains tagname '${tn}'.") or BAIL_OUT;
		# returns: 0=>missing, 1=>exists and has correct value, 2=>exists but has incorrect value
		is($retc->{$tn}, 1, 'WWW::Mechanize::Chrome::Webshot::_check_if_exif_tags_exist_in_image()'." : called and result contains tagname '${tn}' and it exists in the image with expected value of '1'.") or BAIL_OUT(perl2dump($exif)."See above exif data, the value got was '".$retc->{$tn}."'");
	}
	unlink($outfile);

	$cmdline = $atest->[1];
	script_stderr_unlike($FAILURE_REGEX, "stderr of output of script ($ascriptname) checked.") or BAIL_OUT("--BEGIN STDOUT:${stdout}\n--END STDOUT\n--BEGIN STDERR:\n${stderr}\n--END STDERR.\n\nno it failed for above STDOUT/STDERR which this REGEX should not be matching (but it did!): $FAILURE_REGEX"); $num_tests++;
	# we have checked compilation already
	#script_compiles($ascriptname) or print "script ($ascriptname) does not compile.\n"; $num_tests++;
	script_fails($cmdline, {exit=>1}) or print "command succeeded when it should have failed: @$cmdline\n"; $num_tests++;
	script_stderr_like($FAILURE_REGEX, "stderr of output of script ($ascriptname) should be indicating failure and matching the regex $FAILURE_REGEX"); $num_tests++;
	unlink($outfile); # just in case
}

diag "temp dir: $tmpdir ..." if $CLEANUP;

# END
done_testing();
