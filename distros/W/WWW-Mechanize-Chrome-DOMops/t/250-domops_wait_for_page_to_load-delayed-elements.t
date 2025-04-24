#!/usr/bin/env perl

###################################################################
#### NOTE env-var PERL_TEST_TEMPDIR_TINY_NOCLEANUP=1 will stop erasing tmp files
###################################################################

use strict;
use warnings;

use lib 'blib/lib';

our $VERSION = '0.11';

use Test::More;
use Test2::Plugin::UTF8; # rids of the Wide Character in TAP message!
use FindBin;
use WWW::Mechanize::Chrome;
use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;
use Log::Log4perl qw(:easy);
use Test::TempDir::Tiny;
use File::Spec;

use WWW::Mechanize::Chrome::DOMops qw/
	domops_wait_for_page_to_load
/;

# This is for the mech obj, Set priority of root logger to ERROR
Log::Log4perl->easy_init($ERROR);

# At this point we are not sure if the google-chrome binary
# is installed or not, so we will test the creation of a simple
# mech object in an eval and if that fails, then we EXIT this
# test file gracefully without any failure (just a warning
# for the user)
my $cv = eval { WWW::Mechanize::Chrome->chrome_version() };
if( $@ne'' ){
	plan skip_all => "$@\nError: you need to install the google-chrome executable before continuing.\n";
	exit 0; # gracefull exit, all tests have passed! hopefully the user trying to install it has seen this message.
}
diag "found google-chrome executable, version:\n$cv";

my $curdir = $FindBin::Bin;

# verbosity can be 0, 1, 2, 3
my $VERBOSITY = 3; # there are some 2's in the subs to be tested

$WWW::Mechanize::Chrome::DOMops::domops_VERBOSITY = $VERBOSITY;

# the URL to get
my $URL = "file://${curdir}/t-data/site-with-delayed-items/content.html";
# then we look for some elements
# WARNING: HTML from URL may change so these tests may start failing at some point!

# if for debug you change this make sure that it has path in it e.g. ./xyz
#my $tmpdir = tempdir(); # will be erased unless a BAIL_OUT or env var set
#ok(-d $tmpdir, "output dir exists");

#my $js_outfile_tmp = File::Spec->catdir($tmpdir, 'outfile.js');
#diag "Using temp dir '$tmpdir' ...";

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

my $mech_obj = eval {
	WWW::Mechanize::Chrome->new(%default_mech_params)
};
ok($@eq'', "WWW::Mechanize::Chrome->new() : called via an eval() and did not fail.") or BAIL_OUT("failed to create WWW::Mechanize::Chrome object vial an eval() : $@");
ok(defined($mech_obj), "WWW::Mechanize::Chrome->new() : called.") or BAIL_OUT("failed to create WWW::Mechanize::Chrome object");

# JS console.log() messages go to warnout if VERBOSITY is > 2
# we need to keep $console in scope!
my $console = $VERBOSITY > 2 ? $mech_obj->add_listener('Runtime.consoleAPICalled', sub {
	  warn
	      "js console: "
	    . join ", ",
	      map { $_->{value} // $_->{description} }
	      @{ $_[0]->{params}->{args} };
	}) : undef
;

my $ret;

# don't forget to go to the site!
$ret = $mech_obj->get($URL);
ok(defined($ret), "Mech directed to page '$URL'") or BAIL_OUT;

# vanilla
$ret = WWW::Mechanize::Chrome::DOMops::domops_wait_for_page_to_load({
	'mech-obj' => $mech_obj
});
is($ret, 0, 'domops_wait_for_page_to_load()'." : called and got good result/vanilla.") or BAIL_OUT;

# this must fail after the timeout because element does not exist
$ret = domops_wait_for_page_to_load({
	'mech-obj' => $mech_obj,
	'timeout' => 0.5,
	'elements-must-be-present' => '//div[@id="i-do-not-exist"]'
});
is($ret, 2, 'domops_wait_for_page_to_load()'." : called and failed as expected for non-existent element.") or BAIL_OUT;

# this must fail after the timeout because element does not exist YET (it will appear soon)
$ret = domops_wait_for_page_to_load({
	'mech-obj' => $mech_obj,
	'timeout' => 0.5,
	'elements-must-be-present' => '//div[@id="present-after-9s"]'
});
is($ret, 2, 'domops_wait_for_page_to_load()'." : called and failed as expected for non-existent element.") or BAIL_OUT;

# Now, these elements will be appearing after 5,7,9 seconds (from loading the page)

for my $type (qw/any all/){
	# give it an element's xpath to be visible (scalar)
	# this will fail because of short timeout
	$ret = domops_wait_for_page_to_load({
	  'mech-obj' => $mech_obj,
	  'timeout' => 1,
	  'elements-must-be-present-op' => $type,
	  'elements-must-be-present' => [
	    '//div[@id="delayed-div"]/ul[@id="delayed-ul"]/li[@id="present-after-5sXXXXX"]',
	  ],
	});
	is($ret, 2, 'domops_wait_for_page_to_load()'." : called and failed as expected because element is not yet visible and timeout was too short, for type '$type'/1.") or BAIL_OUT;

	$ret = domops_wait_for_page_to_load({
	  'mech-obj' => $mech_obj,
	  'timeout' => 15+1,
	  'elements-must-be-present-op' => $type,
	  'elements-must-be-present' => [
		'//div[@id="delayed-div"]/ul[@id="delayed-ul"]/li[@id="present-after-5s"]',
	  ]
	});
	is($ret, 0, 'domops_wait_for_page_to_load()'." : called and got good result for type '$type'/1.") or BAIL_OUT;

	# give it an element's xpath to be visible (array with 1 element)
	$ret = domops_wait_for_page_to_load({
	  'mech-obj' => $mech_obj,
	  'timeout' => 7+1,
	  'elements-must-be-present-op' => $type,
	  'elements-must-be-present' => [
	    '//div[@id="delayed-div"]/ul[@id="delayed-ul"]/li[@id="present-after-5s"]',
	    '//div[@id="delayed-div"]/ul[@id="delayed-ul"]/li[@id="present-after-7s"]'
	  ]
	});
	is($ret, 0, 'domops_wait_for_page_to_load()'." : called and got good result for type '$type'/2.") or BAIL_OUT;

	# give it an element's xpath to be visible (array with 2 elements)
	$ret = domops_wait_for_page_to_load({
	  'mech-obj' => $mech_obj,
	  'timeout' => 9+1,
	  'elements-must-be-present-op' => $type,
	  'elements-must-be-present' => [
	    '//div[@id="delayed-div"]/ul[@id="delayed-ul"]/li[@id="present-after-5s"]',
	    '//div[@id="delayed-div"]/ul[@id="delayed-ul"]/li[@id="present-after-7s"]',
	    '//div[@id="delayed-div"]/ul[@id="delayed-ul"]/li[@id="present-after-9s"]'
	   ]
	});
	is($ret, 0, 'domops_wait_for_page_to_load()'." : called and got good result for type '$type'/3.") or BAIL_OUT;
} # for type

#diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

# END
done_testing();
