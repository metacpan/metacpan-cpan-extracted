#!/usr/bin/perl

use Test;
use Text::Scan;

BEGIN { plan tests => 72 }

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
	$ref->insert($word, $word);
}


# Have we got everything?
%result = $ref->dump();

for my $word (@wordlist){
    ok(exists $result{$word});
    ok($result{$word}, $word);
}


# Try that again
%result = $ref->dump();

for my $word (@wordlist){
    ok(exists $result{$word});
    ok($result{$word}, $word);
}


# How about three times?

%result = $ref->dump();

for my $word (@wordlist){
    ok(exists $result{$word});
    ok($result{$word}, $word);
}

