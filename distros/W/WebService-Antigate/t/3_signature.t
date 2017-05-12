#!/usr/bin/env perl

use strict;
use Test::More;
use WebService::Antigate;

$WebService::Antigate::FNAME = 'unknown';

my %map = (
	'captcha.jpg' => 'captcha.jpg',
	'captcha.png' => 'captcha.png',
	'captcha.gif' => 'captcha.gif',
	'captcha.txt' => 'unknown'
);

while (my ($name, $result) = each %map) {
	unless (open FH, '<:raw', "t/$name") {
		fail("Can't open t/$name: $!");
		next;
	}
	
	sysread(FH, my $buff, 20);
	is(WebService::Antigate::_name_by_signature($buff), $result, "_name_by_signature($name) eq $result");
	
	close FH;
}

done_testing;
