#!/usr/bin/env perl

use strict;
use warnings;

use lib 'blib/lib';

our $VERSION = '0.11';

use Test::More;
use Test2::Plugin::UTF8; # rids of the Wide Character in TAP message!

use FindBin;
use WWW::Mechanize::Chrome;
use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;
use File::Spec;

use WWW::Mechanize::Chrome::DOMops qw/
	domops_read_dom_element_selectors_from_JSON_string
	domops_read_dom_element_selectors_from_JSON_file
/;

$WWW::Mechanize::Chrome::DOMops::domops_VERBOSITY = 0;

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

# END
done_testing();
