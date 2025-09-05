#!/usr/bin/env perl

###################################################################
#### NOTE env-var PERL_TEST_TEMPDIR_TINY_NOCLEANUP=1 will stop erasing tmp files
###################################################################

use strict;
use warnings;

our $VERSION = '0.12';

use Test::More;
use WWW::Mechanize::Chrome;
use Log::Log4perl qw(:easy);

# This is for the mech obj, Set priority of root logger to ERROR
Log::Log4perl->easy_init(Log::Log4perl::Level::to_priority('ERROR'));
#Log::Log4perl->easy_init($ERROR);

my %default_mech_params = (
	headless => 1,
#	log => $mylogger,
	launch_arg => [
		'--window-size=600x800',
		'--password-store=basic', # do not ask me for stupid chrome account password
#		'--remote-debugging-port=9223',
#		'--enable-logging', # see also log above
		'--disable-gpu',
		'--no-sandbox',
		'--ignore-certificate-errors',
		'--disable-background-networking',
		'--disable-client-side-phishing-detection',
		'--disable-component-update',
		'--disable-hang-monitor',
		'--disable-save-password-bubble',
		'--disable-default-apps',
		'--disable-infobars',
		'--disable-popup-blocking',
	],
);

my $mech_obj = WWW::Mechanize::Chrome->new(%default_mech_params);
ok(defined($mech_obj), "WWW::Mechanize::Chrome->new() : called.") or BAIL_OUT("failed to create WWW::Mechanize::Chrome object");

done_testing();

