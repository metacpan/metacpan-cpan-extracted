#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::HTTP::Server;
use WWW::Chain;
use WWW::Chain::UA::LWP;
use HTTP::Request;

my $server = Test::HTTP::Server->new();

my $ua = WWW::Chain::UA::LWP->new;
isa_ok($ua,'WWW::Chain::UA::LWP');

my $chain = WWW::Chain->new(HTTP::Request->new( GET => $server->uri.'echo' ), sub {
	isa_ok($_[0],'WWW::Chain');
	$_[0]->stash->{a} = 1;
	ok(!$_[0]->done,'Chain is not done');
	isa_ok($_[1],'HTTP::Response');
	is($_[1]->code,'200','First response is a success');
	my $request = HTTP::Request->parse($_[1]->content);
	is($request->uri->as_string,'/echo','First request has proper uri');
	is($request->method,'GET','First request has proper method');
	return HTTP::Request->new( GET => $server->uri.'echo' ), sub {
		isa_ok($_[0],'WWW::Chain');
		$_[0]->stash->{b} = 2;
		ok(!$_[0]->done,'Chain is not done');
		isa_ok($_[1],'HTTP::Response');
		is($_[1]->code,'200','Second response is a success');
		my $request = HTTP::Request->parse($_[1]->content);
		is($request->uri->as_string,'/echo','Second request has proper uri');
		is($request->method,'GET','Second request has proper method');
		return;
	};
});

$ua->request_chain($chain);

ok($chain->done,'Chain is done');

is_deeply($chain->stash,{ a => 1, b => 2 },'Stash is proper');

done_testing;
