#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

{
  package TestWWWChainMethods;
  use Moo;
  extends 'WWW::Chain';

  use HTTP::Request;

  has path_part => (
    is => 'ro',
    required => 1,
  );

  sub start_chain {
    return HTTP::Request->new( GET => 'https://conflict.industries/'.$_[0]->path_part ), 'first_response';
  }

  sub first_response {
    $_[0]->stash->{a} = 1;
    return HTTP::Request->new( GET => 'https://conflict.industries/'.$_[0]->path_part ), 'second_response';
  }

  sub second_response {
    $_[0]->stash->{b} = 2;
    return;
  }
}

my $chain = TestWWWChainMethods->new( path_part => 'wwwchain' );
$chain->request_with_lwp;

print Dumper($chain->stash);

exit 0;