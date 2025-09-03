#!/usr/bin/env perl

###################################################################
#### NOTE env-var PERL_TEST_TEMPDIR_TINY_NOCLEANUP=1 will stop erasing tmp files
###################################################################

use strict;
use warnings;

#use utf8;

our $VERSION = '0.04';

use Test::More;
use Test::More::UTF8;
use FindBin;
use Test::TempDir::Tiny;
use Mojo::Log;

use Data::Roundtrip qw/perl2dump jsonfile2perl no-unicode-escape-permanently/;

use lib ($FindBin::Bin, 'blib/lib');

use WWW::Mechanize::Chrome::Webshot;

my $VERBOSITY = 0; # we need verbosity of 10 (max), so this is not used
my $CLEANUP = (exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && ($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0)) ? 1 : 0;

my $curdir = $FindBin::Bin;

# if for debug you change this make sure that it has path in it e.g. ./xyz
my $tmpdir = tempdir(); # will be erased unless a BAIL_OUT or env var set
ok(-d $tmpdir, "tmpdir exists $tmpdir") or BAIL_OUT;

my $configfile = File::Spec->catfile($curdir, '..', 'config', 'myapp.conf');
ok(-f $configfile, "config file exists ($configfile).") or BAIL_OUT;

# sicily
my $URL = 'https://www.google.com/maps/@38.093577,13.444609,16z';

my $LOGFILE = File::Spec->catfile($tmpdir, 'otpclient.log');
my $log = Mojo::Log->new(path => $LOGFILE);

my $cparams = {
	'configfile' => $configfile,
#	'verbosity' => $VERBOSITY, # use config's
	'cleanup' => $CLEANUP,
	'logger' => $log,
	'launch-mech-on-demand' => 1,
};

my $client = WWW::Mechanize::Chrome::Webshot->new($cparams);
ok(defined($client), 'WWW::Mechanize::Chrome::Webshot->new()'." : called and got defined result.") or BAIL_OUT;
$client->log->info("testing!");
ok(-f $LOGFILE, 'WWW::Mechanize::Chrome::Webshot->new()'." : output log file exists ($LOGFILE).") or BAIL_OUT;
ok(! -z $LOGFILE, 'WWW::Mechanize::Chrome::Webshot->new()'." : output log file exists ($LOGFILE) and it is not empty.") or BAIL_OUT;

# you need to make $mech out of scope so that next use
# is not confused (with already running mech)
$client->shutdown;

# try another more complex:
$LOGFILE = File::Spec->catfile($tmpdir, 'otpclient2.log');
$cparams = {
	'configfile' => $configfile,
#	'verbosity' => $VERBOSITY, # use config's
	'cleanup' => $CLEANUP,
	'logfile' => $LOGFILE,
	'launch-mech-on-demand' => 1,
	'settle-time' => 10,
	'verbosity' => 2,
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

$client = WWW::Mechanize::Chrome::Webshot->new($cparams);
ok(defined($client), 'WWW::Mechanize::Chrome::Webshot->new()'." : called and got defined result.") or BAIL_OUT;
$client->log->info("testing!");
ok(-f $LOGFILE, 'WWW::Mechanize::Chrome::Webshot->new()'." : output log file exists ($LOGFILE).") or BAIL_OUT;
ok(! -z $LOGFILE, 'WWW::Mechanize::Chrome::Webshot->new()'." : output log file exists ($LOGFILE) and it is not empty.") or BAIL_OUT;

# you need to make $mech out of scope so that next use
# is not confused (with already running mech)
$client->shutdown;

# try with a config string
my $configstring = <<'EOCS';
</* $VERSION = '0.04'; */>
</* comments are allowed */>
</* and <% vars %> and <% verbatim sections %> */>
{
	"debug" : {
		"verbosity" : 1,
		</* cleanup temp files on exit */>
		"cleanup" : 1
	},
	"logger" : {
		</* log to file if you uncomment this */>
		</* "filename" : "..." */>
	},
	"constructor" : {
		</* for slow connections */>
	        "settle-time" : "3",
       		"resolution" : "1600x1200",
       		"stop-on-error" : "0",
       		"remove-dom-elements" : []
	},
	"WWW::Mechanize::Chrome" : {
		"headless" : "1",
		"launch_arg" : [
			</* this will change as per the 'resolution' setting above */>
			"--window-size=600x800",
			"--password-store=basic", </* do not ask me for stupid chrome account password */>
		</*	"--remote-debugging-port=9223", */>
		</*	"--enable-logging", */>
			"--disable-gpu",
		</*	"--no-sandbox", NO LONGER VALID */>
			"--ignore-certificate-errors",
			"--disable-background-networking",
			"--disable-client-side-phishing-detection",
			"--disable-component-update",
			"--disable-hang-monitor",
			"--disable-save-password-bubble",
			"--disable-default-apps",
			"--disable-infobars",
			"--disable-popup-blocking"
		]
	}
}
EOCS

$cparams = {
	'configstring' => $configstring,
#	'verbosity' => $VERBOSITY, # use config's
	'cleanup' => $CLEANUP,
	'logger' => $log,
	'launch-mech-on-demand' => 1,
};

$client = WWW::Mechanize::Chrome::Webshot->new($cparams);
ok(defined($client), 'WWW::Mechanize::Chrome::Webshot->new()'." : called and got defined result.") or BAIL_OUT;
$client->log->info("testing!");
ok(-f $LOGFILE, 'WWW::Mechanize::Chrome::Webshot->new()'." : output log file exists ($LOGFILE).") or BAIL_OUT;
ok(! -z $LOGFILE, 'WWW::Mechanize::Chrome::Webshot->new()'." : output log file exists ($LOGFILE) and it is not empty.") or BAIL_OUT;

# you need to make $mech out of scope so that next use
# is not confused (with already running mech)
$client->shutdown;

diag "temp dir: $tmpdir ..." if $CLEANUP;

# END
done_testing();
