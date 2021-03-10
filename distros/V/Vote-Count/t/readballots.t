#!/usr/bin/env perl

use 5.022;
# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
use Test::Exception;
use File::Temp qw/tempfile tempdir/;
use Try::Tiny;
use Path::Tiny;
use Data::Dumper;

use Vote::Count::ReadBallots
  qw/read_ballots write_ballots read_range_ballots write_range_ballots/;

is_deeply(
  Vote::Count::ReadBallots::_choices(':CHOICES:VANILLA:CHOCOLATE:STRAWBERRY'),
  { VANILLA => 1, CHOCOLATE => 1, STRAWBERRY => 1 },
  "_choices private sub returns hash from choices string"
);

subtest 'test read of small good file' => sub {
  my $data1 = read_ballots('t/data/data1.txt');
note( Dumper $data1 ) ;
  is( $data1->{'ballots'}{'MINTCHIP'}{'count'},
    4, 'test the count of a ballot.' );
  is_deeply(
    $data1->{'ballots'}{'CHOCOLATE:MINTCHIP:VANILLA'}{'votes'},
    [qw/CHOCOLATE MINTCHIP VANILLA/],
    'Test an array of votes'
  );
  is( $data1->{'ballots'}{'CHOCOLATE:MINTCHIP:VANILLA'}{'votevalue'},
    1, 'test insertion of default votevalue 1');
  is_deeply(
    $data1->{'options'},
    { 'rcv' => 1 },
    'parsed ballot set rcv in options'
  );
  is( $data1->{'votescast'},      10, 'confirm count of votescast' );
  is( $data1->{'options'}{'rcv'}, 1,  'option for rcv ballot should be set' );
# test2 isnt barfs at undef, even though undef doesn't match the value provided
  my $optionrange =
    $data1->{'options'}{'range'} ? $data1->{'options'}{'range'} : 0;
  isnt( $optionrange, 1, 'option for range ballot should NOT be set' );
  note 'votescast ' . $data1->{'votescast'};
};

subtest 'test some bad files' => sub {
  dies_ok(
    sub {
      read_ballots('t/data/badballot1.txt');
    },
    "Ballot redefining Choices - dies"
  );
  throws_ok(
    sub {
      read_ballots('t/data/badballot1.txt');
    },
    qr/redefines CHOICES/,
    'emitted redefines CHOICES error'
  );
  dies_ok(
    sub {
      read_ballots('t/data/badballot2.txt');
    },
    'Ballot with undefined choice'
  );
  throws_ok(
    sub {
      read_ballots('t/data/badballot2.txt');
    },
    qr/TANGERINE is not in defined choice list:/,
    'emitted TANGERINE is not in defined choice list:'
  );
};

subtest 'comments' => sub {
  my $uncommented = read_ballots('t/data/data1.txt');
  is( $uncommented->{'comment'}, '', 'file with no comment has no comment' );
  my $commented = read_ballots('t/data/data2.txt');
  like( $commented->{'comment'},
    qr/Comment 1/, 'commented file has first comment' );
  like( $commented->{'comment'},
    qr/Comment 2/, 'commented file has second comment' );
};

subtest 'write_ballots' => sub {
  my $rewrite = <<'REWRIT';
# Data rewritten in compressed form.
CHOICES:CHOCOLATE:STRAWBERRY:VANILLA
1:CHOCOLATE:STRAWBERRY
2:CHOCOLATE:VANILLA
3:VANILLA:CHOCOLATE
1:VANILLA:CHOCOLATE:STRAWBERRY
1:VANILLA:STRAWBERRY
REWRIT

  my ( $dst, $dstFile ) = tempfile();
  close $dst;
  note("rewritten ballots to: $dstFile");
  my $uncomp = read_ballots('t/data/uncompressed.txt');
  write_ballots( $uncomp, $dstFile );
  my $confirmdata = path($dstFile)->slurp();
  is( $confirmdata, $rewrite, "rewritten file contents confirmed" );
};

my $tnseechoices = {
  'CHATTANOOGA' => 1,
  'KNOXVILLE'   => 1,
  'MEMPHIS'     => 1,
  'NASHVILLE'   => 1
};

subtest 'read score/range ballots' => sub {
  my $tr1 = read_range_ballots('t/data/tennessee.range.json');
  ok( $tr1, 'read ballots from json' );
  is( $tr1->{'votescast'}, 100, 'check count of votescast' );
  is( $tr1->{'ballots'}[2]{'votes'}{'KNOXVILLE'}, 3, 'check a nested value' );

  is_deeply( $tr1->{'choices'}, $tnseechoices,
    'conversion of choices from array in range data to hash' );
  my $tr2 = read_range_ballots( 't/data/tennessee.range.yml', 'yaml' );
  ok( $tr2, 'read ballots from yaml' );
  is( $tr2->{'votescast'}, 100, 'check count of votescast' );
  is( $tr2->{'ballots'}[2]{'votes'}{'MEMPHIS'}, 1, 'check a nested value' );

# test2 isnt barfs at undef, even though undef doesn't match the value provided
  my $optionrcv = $tr2->{'options'}{'rcv'} ? $tr2->{'options'}{'rcv'} : 0;
  isnt( $optionrcv, 1, 'option for rcv ballot should NOT be set' );
  is( $tr2->{'options'}{'range'}, 1,
    'option for range ballot should be set' );
};

subtest 'write score/range ballots' => sub {
  my $write1 = read_range_ballots( 't/data/tennessee.range.yml', 'yaml' );
  write_range_ballots( $write1, '/tmp/writerange.yml', 'json' );
  my $readback = read_range_ballots( '/tmp/writerange.yml', 'yaml' );
  is_deeply( $readback->{'choices'},
    $tnseechoices, 'readback and check choices' );
  is( $readback->{'votescast'}, 100, 'check count of votescast' );
};

done_testing();
