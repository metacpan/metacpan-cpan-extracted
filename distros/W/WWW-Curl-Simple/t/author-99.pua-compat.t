#!/usr/bin/perl -w

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}


use strict;
use Test::More tests => 4;
use WWW::Curl::Simple;


my $pua = WWW::Curl::Simple->new();
#$pua->timeout(10);
#$pua->in_order(1);

{
    $pua->register(HTTP::Request->new(GET => 'http://en.wikipedia.org/wiki/Main_Page'));
    $pua->register(HTTP::Request->new(GET => 'http://www.yahoo.com'));
    
    my $results = $pua->wait;
    
    foreach (keys %$results) {
        my $req = $results->{$_};
        isa_ok($req, "WWW::Curl::Simple::Request");
        ok($req->response->is_success or $req->response->is_redirect, 
            "we have success!  " . $req->response->code
        );
    }
    
}
