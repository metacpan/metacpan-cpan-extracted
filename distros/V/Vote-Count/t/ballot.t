#!/usr/bin/env perl

use 5.022;
# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
use Test::Exception;
use Data::Printer;

use Path::Tiny;

use Vote::Count::ReadBallots 'read_ballots';

is_deeply(
  Vote::Count::ReadBallots::_choices(':CHOICES:VANILLA:CHOCOLATE:STRAWBERRY'),
  {  VANILLA => 1, CHOCOLATE => 1, STRAWBERRY => 1} ,
  "_choices private sub returns hash from choices string");

subtest 'test read of small good file' => sub {
  my $data1 = read_ballots('t/data/data1.txt');
  is( $data1->{'ballots'}{'MINTCHIP'}{'count'},
      4,
      'test the count of a ballot.');
  is_deeply(
    $data1->{'ballots'}{'CHOCOLATE:MINTCHIP:VANILLA'}{'votes'},
    [ qw/CHOCOLATE MINTCHIP VANILLA/ ],
    'Test an array of votes'
  );
  is_deeply( $data1->{'options'},
  { 'rcv' => 1 },
  'parsed ballot set rcv in options')
};

subtest 'test some bad files' => sub {
  dies_ok( sub {
    read_ballots( 't/data/badballot1.txt') },
    "Ballot redefining Choices - dies" );
  throws_ok( sub {
    read_ballots( 't/data/badballot1.txt') },
    qr/redefines CHOICES/,
    'emitted redefines CHOICES error' );
  dies_ok( sub {
    read_ballots( 't/data/badballot2.txt') },
    'Ballot with undefined choice' );
  throws_ok( sub {
    read_ballots( 't/data/badballot2.txt') },
    qr/TANGERINE is not in defined choice list:/,
    'emitted TANGERINE is not in defined choice list:' );
};

done_testing();