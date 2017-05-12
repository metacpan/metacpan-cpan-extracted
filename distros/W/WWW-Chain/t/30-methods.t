#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use WWW::Chain;
use HTTP::Request;
use HTTP::Response;

{
	package TestWWWChainMethods;
	use Moo;
	extends 'WWW::Chain';

	sub first_request {
		main::isa_ok($_[0],'WWW::Chain');
		$_[0]->stash->{a} = 1;
		main::isa_ok($_[1],'HTTP::Response');
		return HTTP::Request->new( GET => 'http://duckduckgo.com/' ), "second_request";
	}

	sub second_request {
		main::isa_ok($_[0],'WWW::Chain');
		$_[0]->stash->{b} = 2;
		main::isa_ok($_[1],'HTTP::Response');
		return;
	}
}

my $chain = TestWWWChainMethods->new(HTTP::Request->new( GET => 'http://duckduckgo.com/' ), 'first_request');
isa_ok($chain,'TestWWWChainMethods');

$chain->next_responses(HTTP::Response->new);
ok(!$chain->done,'Chain is not done');

$chain->next_responses(HTTP::Response->new);
ok($chain->done,'Chain is done');

is_deeply($chain->stash,{ a => 1, b => 2 },'Stash is proper');

done_testing;
