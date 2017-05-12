#!perl
use strict;
use warnings;
use lib 'lib';
use Test::Expect;
use Test::More tests => 20;

require_ok('Expect');

ok(1, "True");

foreach my $filename ('read', 'readline') {
  ok($filename, "Testing $filename");
  expect_run(
    command => [$^X, $filename, "world"],
    prompt  => $filename . ': ',
    quit    => 'quit',
  );
  isa_ok(expect_handle(), 'Expect');
  expect_like(qr/Hi world, to $filename/, "expect_like");
  expect_is("* Hi world, to $filename", "expect_is");
  expect_send("ping", "expect_send");
  expect_is("pong", "expect_is receiving expect_send");
  expect("ping", "pong", "expect");
};
