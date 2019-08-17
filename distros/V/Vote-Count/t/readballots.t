#!/usr/bin/env perl

use 5.022;
# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
use Test::Exception;
use Data::Printer;
use File::Temp qw/tempfile tempdir/;

use Path::Tiny;

use Vote::Count::ReadBallots qw/read_ballots write_ballots/;

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
  'parsed ballot set rcv in options');
  is( $data1->{'votescast'}, 10, 'confirm count of votescast');
   note 'votescast ' . $data1->{'votescast'};
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

subtest 'comments' => sub {
  my $uncommented = read_ballots('t/data/data1.txt');
  is ($uncommented->{'comment'}, '', 'file with no comment has no comment');
  my $commented = read_ballots('t/data/data2.txt');
  like( $commented->{'comment'}, qr/Comment 1/,
      'commented file has first comment');
  like( $commented->{'comment'}, qr/Comment 2/,
      'commented file has second comment');
};



subtest 'write_ballots' => sub {
  my $rewrite =<<'REWRIT';
# Data rewritten in compressed form.
CHOICES:CHOCOLATE:STRAWBERRY:VANILLA
1:CHOCOLATE:STRAWBERRY
2:CHOCOLATE:VANILLA
3:VANILLA:CHOCOLATE
1:VANILLA:CHOCOLATE:STRAWBERRY
1:VANILLA:STRAWBERRY
REWRIT

  my ( $dst, $dstFile ) = tempfile(); close $dst;
  note ( "rewritten ballots to: $dstFile");
  my $uncomp = read_ballots('t/data/uncompressed.txt');
  write_ballots( $uncomp, $dstFile );
  my $confirmdata = path($dstFile)->slurp();
  is ($confirmdata, $rewrite, "rewritten file contents confirmed");
};

done_testing();