#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use WWW::Chain;
use HTTP::Request;
use HTTP::Response;

my $chain = WWW::Chain->new(HTTP::Request->new( GET => 'http://duckduckgo.com/' ), sub {
	isa_ok($_[0],'WWW::Chain');
	$_[0]->stash->{a} = 1;
	isa_ok($_[1],'HTTP::Response');
	return HTTP::Request->new( GET => 'http://duckduckgo.com/' ), sub {
		isa_ok($_[0],'WWW::Chain');
		$_[0]->stash->{b} = 2;
		isa_ok($_[1],'HTTP::Response');
		return;
	};
});

isa_ok($chain,'WWW::Chain');

$chain->next_responses(HTTP::Response->new);
ok(!$chain->done,'Chain is not done');

$chain->next_responses(HTTP::Response->new);
ok($chain->done,'Chain is done');

is_deeply($chain->stash,{ a => 1, b => 2 },'Stash is proper');

done_testing;
