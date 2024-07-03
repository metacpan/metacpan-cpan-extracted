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

  use HTTP::Request;

  sub start_chain {
    return HTTP::Request->new( GET => 'http://www.chain.internal/' ), 'first_response';
  }

  sub first_response {
    $_[0]->stash->{a} = 1;
    return HTTP::Request->new( GET => 'http://www.chain.internal/' ), 'second_response';
  }

  sub second_response {
    $_[0]->stash->{b} = 2;
    return;
  }
}

my $chain = TestWWWChainMethods->new;
isa_ok($chain,'TestWWWChainMethods');

$chain->next_responses(HTTP::Response->new);
ok(!$chain->done,'Chain is not done');

$chain->next_responses(HTTP::Response->new);
ok($chain->done,'Chain is done');

is_deeply($chain->stash,{ a => 1, b => 2 },'Stash is proper');

done_testing;
