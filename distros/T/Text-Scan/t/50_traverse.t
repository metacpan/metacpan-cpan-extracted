#!/usr/bin/perl

use Test;
use Text::Scan;

BEGIN { plan tests => 36 }

$ref = new Text::Scan;

@wordlist = qw(
	banana
	bananas
	pajamas
	words
	forms
	worms
	firewater
	tirewater
	tidewater
	tidewader
	telephone
	telephony
);

for my $word (@wordlist) {
	$ref->insert($word, "~");
}

@result = sort $ref->keys();

ok($result[0], 'banana');
ok($result[1], 'bananas');
ok($result[2], 'firewater');
ok($result[3], 'forms');
ok($result[4], 'pajamas');
ok($result[5], 'telephone');
ok($result[6], 'telephony');
ok($result[7], 'tidewader');
ok($result[8], 'tidewater');
ok($result[9], 'tirewater');
ok($result[10], 'words');
ok($result[11], 'worms');


# Try that again

@result = sort $ref->keys();

ok($result[0], 'banana');
ok($result[1], 'bananas');
ok($result[2], 'firewater');
ok($result[3], 'forms');
ok($result[4], 'pajamas');
ok($result[5], 'telephone');
ok($result[6], 'telephony');
ok($result[7], 'tidewader');
ok($result[8], 'tidewater');
ok($result[9], 'tirewater');
ok($result[10], 'words');
ok($result[11], 'worms');



# How about three times?

@result = sort $ref->keys();

ok($result[0], 'banana');
ok($result[1], 'bananas');
ok($result[2], 'firewater');
ok($result[3], 'forms');
ok($result[4], 'pajamas');
ok($result[5], 'telephone');
ok($result[6], 'telephony');
ok($result[7], 'tidewader');
ok($result[8], 'tidewater');
ok($result[9], 'tirewater');
ok($result[10], 'words');
ok($result[11], 'worms');



