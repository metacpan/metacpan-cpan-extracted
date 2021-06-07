#!/usr/bin/env perl

use 5.024;

# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
# use Test::Exception;
use Test2::Tools::Exception qw/dies lives/;
use Data::Dumper;
use feature qw /postderef signatures/;

use Path::Tiny;

use Vote::Count;
use Vote::Count::ReadBallots 'read_ballots', 'read_range_ballots';
use Vote::Count::Borda;

subtest '_bordashrinkballot private method' => sub {
  my $VC1 = Vote::Count->new(
    BallotSet  => read_ballots('t/data/data1.txt'),
    bordadepth => 5
  );
  my $shrunken1 = Vote::Count::Borda::_bordashrinkballot( $VC1->BallotSet(),
    { 'CARAMEL' => 1, 'STRAWBERRY' => 1, 'MINTCHIP' => 1 } );

  is( $shrunken1->{'CHOCOLATE:MINTCHIP:VANILLA'}{'votes'}[0],
    'MINTCHIP', 'Check the remaining member of a reduced ballot' );

  is( $shrunken1->{'MINTCHIP'}{'count'},
    4, 'Check that a choice with multiple votes still has them' );
  is( scalar( $shrunken1->{'MINTCHIP:CARAMEL:RUMRAISIN'}{'votes'}->@* ),
    2, 'choice that still has multipe choices has the right number' );
  # Test that if a ballot has no active choices is not in the shrunk ballot.
  my $shrunken2 = Vote::Count::Borda::_bordashrinkballot( $VC1->BallotSet(),
    { 'CARAMEL' => 1, 'STRAWBERRY' => 1, 'MINTCHIP' => 0 } );
  is( $shrunken2->{'MINTCHIP'}, undef,
'mintchip only ballot should be removed since it has no votes with mintchip out of active set'
  );
};

subtest '_dobordacount private method' => sub {
  my $bordatable = {
    'VANILLA' => { 1 => 4, 2 => 6, 3 => 9 },
    'RAISIN'  => { 1 => 6, 3 => 2 },
    'CHERRY'  => { 2 => 5 }
  };
  my $lightweight = sub { return 1 };
  my $dbc = Vote::Count->new(
    BallotSet   => read_ballots('t/data/data1.txt'),
    bordaweight => $lightweight
  );

  # need an object for this test. the lightweight
  # bordaweight just returns 1 so an
  # empty hashref is passed as a placeholder.
  my $counted = $dbc->_dobordacount( $bordatable, $dbc->Active() );
  is( $counted->{'VANILLA'}, 19, 'check count for first choice' );
  is( $counted->{'RAISIN'},  8,  'check count for second choice' );
  is( $counted->{'CHERRY'},  5,  'check count for third choice' );
};

subtest 'bordadepth at 5, standard method' => sub {
  my $VA1 = Vote::Count->new(
    BallotSet  => read_ballots('t/data/data1.txt'),
    bordadepth => 5
  );
  my $expectA1 = {
    CARAMEL    => 4,
    CHOCOLATE  => 10,
    MINTCHIP   => 32,
    PISTACHIO  => 5,
    ROCKYROAD  => 4,
    RUMRAISIN  => 3,
    STRAWBERRY => 3,
    VANILLA    => 20,
  };
  my $A1Rank = $VA1->Borda($expectA1);

  is_deeply( $A1Rank->RawCount(), $expectA1,
    "Borda counted small set no active list forced depth 5" );

  my $testweight = sub {
    my $x = shift;
    if    ( $x == 1 ) { return 12 }
    elsif ( $x == 2 ) { return 6 }
    elsif ( $x == 3 ) { return 4 }
    elsif ( $x == 4 ) { return 3 }
    else              { return 0 }
  };

  my $VC2 = Vote::Count->new(
    BallotSet   => read_ballots('t/data/data2.txt'),
    bordaweight => $testweight,
  );

  my ($A2) = $VC2->Borda(
    {
      'VANILLA'   => 1,
      'CHOCOLATE' => 1,
      'CARAMEL'   => 1,
    }
  );

  my $expectA2 = {
    CARAMEL   => 12,
    CHOCOLATE => 54,
    VANILLA   => 114
  };

  is_deeply( $A2->RawCount(), $expectA2,
    "Borda counted a small set with AN active list" );

  is_deeply( $A2->RawCount()->{'PISTACHIO'},
    undef,
    'PISTACHIO was removed from active set, it should not be defined.' );

  my $A3 = $VC2->Borda(
    {
      'VANILLA'   => 1,
      'CHOCOLATE' => 1,
      'CARAMEL'   => 1,
      'PISTACHIO' => 1
    }
  );
  my $expectA3 = {
    CARAMEL   => 12,
    CHOCOLATE => 50,
    PISTACHIO => 24,
    VANILLA   => 102
  };
  is_deeply( $A3->RawCount(), $expectA3,
    'Check the count with Pistachio returned to active set.' );

};

subtest 'tests with default borda weighting' => sub {

  # THis time set no depth and use a ballot set
  # with 12 choices
  my $BC1 = Vote::Count->new( BallotSet => read_ballots('t/data/ties1.txt') );

  is( $BC1->unrankdefault(), 0, 'unrankdefault has a default value of 0' );
  my $expectB1 = {
    BUBBLEGUM  => 68,
    CARAMEL    => 44,
    CHERRY     => 66,
    CHOCCHUNK  => 24,
    CHOCOLATE  => 62,
    FUDGESWIRL => 72,
    MINTCHIP   => 88,
    PISTACHIO  => 48,
    ROCKYROAD  => 59,
    RUMRAISIN  => 48,
    STRAWBERRY => 40,
    VANILLA    => 72
  };

  my ($B1Rank) = $BC1->Borda();

  is_deeply( $B1Rank->RawCount(), $expectB1,
    "Small set no active list default depth of 0" );

  # since the activeset hash is used only for its keys as long
  # as values are true the same hashref can also hold the answwers.
  my $activeset = {
    BUBBLEGUM => 22,
    CARAMEL   => 16,
    CHERRY    => 24,
    VANILLA   => 24,
  };
  my ($C1Rank) = $BC1->Borda($activeset);
  is_deeply( $C1Rank->RawCount(), $activeset,
    "small set WITH active list default depth of 0" );

};

subtest 'test setting unrankeddefault' => sub {
  my $ur1 = Vote::Count->new(
    BallotSet     => read_ballots('t/data/data2.txt'),
    unrankdefault => 1,
  );
  is( $ur1->unrankdefault(), 1, 'unrankdefault has been set to 1' );
  like(
    dies {
      $ur1->Borda( { 'BUBBLEGUM' => 1, 'CARAMEL' => 1, 'CHERRY' => 1 } )
    },
    qr/unrankdefault other than 0 is not compatible with overriding/,
q/DIES because unrankdefault other than 0 is not compatible with overriding active set/
  );
  my $expectur1 = {
    'STRAWBERRY' => 40,
    'MINTCHIP'   => 66,
    'ROCKYROAD'  => 27,
    'PISTACHIO'  => 29,
    'CHOCOLATE'  => 58,
    'VANILLA'    => 77,
    'RUMRAISIN'  => 20,
    'CARAMEL'    => 21
  };
  is_deeply( $ur1->Borda()->RawCount(),
    $expectur1, 'check counts with unrankdefault at 1' );
  my $ur2 = Vote::Count->new(
    BallotSet     => read_ballots('t/data/data2.txt'),
    unrankdefault => -2,
  );
  my $expectur2 = {
    'VANILLA'    => 62,
    'STRAWBERRY' => 10,
    'CHOCOLATE'  => 37,
    'ROCKYROAD'  => -12,
    'PISTACHIO'  => -10,
    'MINTCHIP'   => 45,
    'RUMRAISIN'  => -22,
    'CARAMEL'    => -21
  };
  is_deeply( $ur2->Borda()->RawCount(),
    $expectur2, 'check counts with unrankdefault at -2' );

};

done_testing();
