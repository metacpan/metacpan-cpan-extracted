#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;
use HTTP::Response;

use WWW::Firecrawl::Error;

subtest 'basic construction + accessors' => sub {
  my $e = WWW::Firecrawl::Error->new(
    type => 'api',
    message => 'Bad Request',
    status_code => 400,
  );
  isa_ok $e, 'WWW::Firecrawl::Error';
  is $e->type, 'api';
  is $e->message, 'Bad Request';
  is $e->status_code, 400;
  is $e->response, undef;
  is $e->data, undef;
  is $e->url, undef;
  is $e->attempt, undef;
};

subtest 'is_* type checks' => sub {
  for my $t (qw( transport api job scrape page )) {
    my $e = WWW::Firecrawl::Error->new( type => $t, message => 'x' );
    my $method = "is_$t";
    ok $e->$method, "$method true for type=$t";
    for my $other (qw( transport api job scrape page )) {
      next if $other eq $t;
      my $other_m = "is_$other";
      ok !$e->$other_m, "$other_m false for type=$t";
    }
  }
};

subtest 'string overload' => sub {
  my $e = WWW::Firecrawl::Error->new( type => 'api', message => 'nope' );
  is "$e", 'nope', 'stringifies to message';
  ok "prefix $e suffix" eq 'prefix nope suffix', 'interpolates';
  ok $e =~ /nope/, 'regex matches stringified form';
};

subtest 'response attribute carries HTTP::Response' => sub {
  my $r = HTTP::Response->new(500);
  my $e = WWW::Firecrawl::Error->new(
    type => 'api', message => 'ISE', response => $r, attempt => 2,
  );
  isa_ok $e->response, 'HTTP::Response';
  is $e->response->code, 500;
  is $e->attempt, 2;
};

subtest 'required fields' => sub {
  like exception { WWW::Firecrawl::Error->new( message => 'x' ) },
       qr/type/, 'type is required';
  like exception { WWW::Firecrawl::Error->new( type => 'api' ) },
       qr/message/, 'message is required';
};

done_testing;
