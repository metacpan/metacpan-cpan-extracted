#!/usr/bin/perl -w

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}


use strict;
use Test::More;
use WWW::Curl::Simple;

my @urls = (
'http://en.wikipedia.org/wiki/Main_Page',
'http://www.yahoomypoo.com',
);

plan tests => 1;

my $curl = WWW::Curl::Simple->new(fatal => 0);

{
    $curl->add_request(HTTP::Request->new(GET => $_)) foreach (@urls);
    
    my @res = $curl->perform;
    
    ok("we live! :p");
    
}
