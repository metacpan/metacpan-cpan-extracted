#!/usr/bin/perl

use strict;
use warnings;

use Test::Mojo::Plack;
use Test::More;

my $t = Test::Mojo::Plack->new();

# Setup a temporary server
my $daemon = Mojo::Server::Daemon->new();
$daemon->on(request => sub {
  my ($daemon, $tx) = @_;
  # Response
  $tx->res->code(200);
  $tx->res->headers->content_type('text/plain');
  $tx->res->body("Hello World");
  # Resume transaction
  $tx->resume;
});
my $id   = $daemon->listen(['http://127.0.0.1'])->start->acceptors->[0];
my $port = $daemon->ioloop->acceptor($id)->handle->sockport;

$t->get_ok("http://localhost:$port")->status_is(200)->content_type_is('text/plain')->content_is('Hello World');

my $psgi_subref = sub {
    my $env = shift;
    return [ 200, [ 'Content-Type' => 'text/plain' ], [ "Hello World" ] ],
};

my $tp = Test::Mojo::Plack->new($psgi_subref);

$tp->get_ok('/')->status_is('200')->content_type_is('text/plain')->content_is('Hello World');

done_testing;
