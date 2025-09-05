#!/usr/bin/env perl

###################################################################
#### NOTE env-var PERL_TEST_TEMPDIR_TINY_NOCLEANUP=1 will stop erasing tmp files
###################################################################

use strict;
use warnings;

use lib 'blib/lib';

our $VERSION = '0.13';

use Test::More;
use Test2::Plugin::UTF8; # rids of the Wide Character in TAP message!

use FindBin;

use Log::Log4perl qw(:easy);
use WWW::Mechanize::Chrome;
use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;
use File::Spec;
use Test::TempDir::Tiny;

use WWW::Mechanize::Chrome::DOMops qw/
	domops_read_dom_element_selectors_from_JSON_string
	domops_read_dom_element_selectors_from_JSON_file
/;

$WWW::Mechanize::Chrome::DOMops::domops_VERBOSITY = 0;

Log::Log4perl->easy_init($ERROR);

my $success_file = File::Spec->catdir($FindBin::Bin, 't-data', 'json-dom-selectors', 'success.json');
ok(-f $success_file, "input json file '$success_file' exists.") or BAIL_OUT;
my $ret = domops_read_dom_element_selectors_from_JSON_file($success_file);
ok(defined($ret), 'domops_read_dom_element_selectors_from_JSON_file()'." : called and got back defined result.");
is(ref($ret), 'ARRAY', 'domops_read_dom_element_selectors_from_JSON_file()'." : called and got back ARRAY.");
ok(scalar(@$ret)>0, 'domops_read_dom_element_selectors_from_JSON_file()'." : called and got back ARRAY which has some items.");
for (@$ret){
	is(ref($_), 'HASH', 'domops_read_dom_element_selectors_from_JSON_file()'." : item of ARRAY is HASH.");
}

my $fail_file = File::Spec->catdir($FindBin::Bin, 't-data', 'json-dom-selectors', 'fail.json');
ok(-f $fail_file, "input json file '$fail_file' exists.") or BAIL_OUT;
$ret = domops_read_dom_element_selectors_from_JSON_file($fail_file);
is($ret, undef, 'domops_read_dom_element_selectors_from_JSON_file()'." : called and got back undefined result as expected for malformed input.");

# and read contents of files and run the string() versions (although they have been tested above)
my ($FH, $jsonstr);
ok(open($FH, '<:encoding(UTF-8)', $success_file), "input file '$success_file' opened for reading.") or BAIL_OUT("no it failed: $!");
{ local $/ = undef; $jsonstr = <$FH> } close $FH;
$ret = domops_read_dom_element_selectors_from_JSON_string($jsonstr);
ok(defined($ret), 'domops_read_dom_element_selectors_from_JSON_string()'." : called and got back defined result.");
is(ref($ret), 'ARRAY', 'domops_read_dom_element_selectors_from_JSON_string()'." : called and got back ARRAY.");
ok(scalar(@$ret)>0, 'domops_read_dom_element_selectors_from_JSON_string()'." : called and got back ARRAY which has some items.");
for (@$ret){
	is(ref($_), 'HASH', 'domops_read_dom_element_selectors_from_JSON_string()'." : item of ARRAY is HASH.");
}

ok(open($FH, '<:encoding(UTF-8)', $fail_file), "input file '$fail_file' opened for reading.") or BAIL_OUT("no it failed: $!");
{ local $/ = undef; $jsonstr = <$FH> } close $FH;
$ret = domops_read_dom_element_selectors_from_JSON_string($jsonstr);
is($ret, undef, 'domops_read_dom_element_selectors_from_JSON_string()'." : called and got back undefined result as expected for malformed input.");



######
## now repeat but with a logger object set logging to a file and check file contents
## NOTE: chrome-mechanize will still log to the Log4crap
######

# if for debug you change this make sure that it has path in it e.g. ./xyz
my $tmpdir = tempdir(); # will be erased unless a BAIL_OUT or env var set
ok(-d $tmpdir, "output dir exists");

my $LOGFILE = File::Spec->catfile($tmpdir, 'domops.log');
$WWW::Mechanize::Chrome::DOMops::domops_VERBOSITY = 10;
$WWW::Mechanize::Chrome::DOMops::domops_LOGGER = Mojo::Log->new(path=>$LOGFILE);

$success_file = File::Spec->catdir($FindBin::Bin, 't-data', 'json-dom-selectors', 'success.json');
ok(-f $success_file, "input json file '$success_file' exists.") or BAIL_OUT;
$ret = domops_read_dom_element_selectors_from_JSON_file($success_file);
ok(defined($ret), 'domops_read_dom_element_selectors_from_JSON_file()'." : called and got back defined result.");
is(ref($ret), 'ARRAY', 'domops_read_dom_element_selectors_from_JSON_file()'." : called and got back ARRAY.");
ok(scalar(@$ret)>0, 'domops_read_dom_element_selectors_from_JSON_file()'." : called and got back ARRAY which has some items.");
for (@$ret){
	is(ref($_), 'HASH', 'domops_read_dom_element_selectors_from_JSON_file()'." : item of ARRAY is HASH.");
}

my ($FH2, $contents2);
ok(open($FH2, '<', $LOGFILE), "Logfile '$LOGFILE' opened for reading.") or BAIL_OUT("failed to open logfile '$LOGFILE' for reading, $!");
{ local $/ = undef; $contents2 = <$FH2> } close $FH2;
ok($contents2=~/called for JSON file/, "Logfile '$LOGFILE' contains logged text.") or BAIL_OUT("${contents2}.\nno, it contains above data only (logfile '$LOGFILE').");


$fail_file = File::Spec->catdir($FindBin::Bin, 't-data', 'json-dom-selectors', 'fail.json');
ok(-f $fail_file, "input json file '$fail_file' exists.") or BAIL_OUT;
$ret = domops_read_dom_element_selectors_from_JSON_file($fail_file);
is($ret, undef, 'domops_read_dom_element_selectors_from_JSON_file()'." : called and got back undefined result as expected for malformed input.");

ok(open($FH2, '<', $LOGFILE), "Logfile '$LOGFILE' opened for reading.") or BAIL_OUT("failed to open logfile '$LOGFILE' for reading, $!");
{ local $/ = undef; $contents2 = <$FH2> } close $FH2;
is(()=$contents2=~/error, specified dom elements to be removed \(see above\) failed to be parsed as JSON/g, 1, "Logfile '$LOGFILE' contains logged text.") or BAIL_OUT("${contents2}.\nno, it contains above data only (logfile '$LOGFILE').");

# and read contents of files and run the string() versions (although they have been tested above)
ok(open($FH, '<:encoding(UTF-8)', $success_file), "input file '$success_file' opened for reading.") or BAIL_OUT("no it failed: $!");
{ local $/ = undef; $jsonstr = <$FH> } close $FH;
$ret = domops_read_dom_element_selectors_from_JSON_string($jsonstr);
ok(defined($ret), 'domops_read_dom_element_selectors_from_JSON_string()'." : called and got back defined result.");
is(ref($ret), 'ARRAY', 'domops_read_dom_element_selectors_from_JSON_string()'." : called and got back ARRAY.");
ok(scalar(@$ret)>0, 'domops_read_dom_element_selectors_from_JSON_string()'." : called and got back ARRAY which has some items.");
for (@$ret){
	is(ref($_), 'HASH', 'domops_read_dom_element_selectors_from_JSON_string()'." : item of ARRAY is HASH.");
}

ok(open($FH2, '<', $LOGFILE), "Logfile '$LOGFILE' opened for reading.") or BAIL_OUT("failed to open logfile '$LOGFILE' for reading, $!");
{ local $/ = undef; $contents2 = <$FH2> } close $FH2;
is(()=$contents2=~/error, call to domops_read_dom_element_selectors_from_JSON_string\(\) has failed for input file/g, 1, "Logfile '$LOGFILE' contains logged text.") or BAIL_OUT("${contents2}.\nno, it contains above data only (logfile '$LOGFILE').");

ok(open($FH, '<:encoding(UTF-8)', $fail_file), "input file '$fail_file' opened for reading.") or BAIL_OUT("no it failed: $!");
{ local $/ = undef; $jsonstr = <$FH> } close $FH;
$ret = domops_read_dom_element_selectors_from_JSON_string($jsonstr);
is($ret, undef, 'domops_read_dom_element_selectors_from_JSON_string()'." : called and got back undefined result as expected for malformed input.");

ok(open($FH2, '<', $LOGFILE), "Logfile '$LOGFILE' opened for reading.") or BAIL_OUT("failed to open logfile '$LOGFILE' for reading, $!");
{ local $/ = undef; $contents2 = <$FH2> } close $FH2;
# we now have 2 of these messages:
is(()=$contents2=~/error, specified dom elements to be removed \(see above\) failed to be parsed as JSON/g, 2, "Logfile '$LOGFILE' contains logged text.") or BAIL_OUT("${contents2}.\nno, it contains above data only (logfile '$LOGFILE').");

diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

# END
done_testing();
