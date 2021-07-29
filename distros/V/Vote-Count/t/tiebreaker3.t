#!/usr/bin/env perl

use 5.024;
# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
use Test::Exception;
use Test2::Tools::Exception qw/dies lives/;
use File::Temp qw/tempfile tempdir/;
# use Vote::Count::Charge::Utility qw/ WeightedTable /;
# use Test::Exception;
use Carp;
use Data::Dumper;

use Path::Tiny;
# use Storable 'dclone';

use Vote::Count;
use Vote::Count::ReadBallots 'read_ballots';

use feature qw /postderef signatures/;
no warnings 'experimental';
use Data::Printer;

my $D = Vote::Count->new(
  BallotSet      => read_ballots('t/data/ties3.txt'),
  TieBreakMethod => 'precedence',
  PrecedenceFile => 't/data/ties3precedence.txt',
);

my $E = Vote::Count->new(
  BallotSet                    => read_ballots('t/data/ties1.txt'),
  TieBreakMethod               => 'approval',
  PrecedenceFile               => 't/data/tiebreakerprecedence1.txt',
  TieBreakerFallBackPrecedence => 1,
);

subtest 'UnTieList' => sub {

  is_deeply(
    [ $E->UnTieList( ranking1 => 'precedence', tied => ['VANILLA'] ) ],
    ['VANILLA'], 'precedence with 1 just returned it' );

  is_deeply(
    [ $E->UnTieList( ranking1 => 'Approval', tied => ['CHOCOLATE'] ) ],
    ['CHOCOLATE'], 'approval with 1 just returned it' );

  my @tied = qw( CARAMEL CHERRY STRAWBERRY CHOCOLATE RUMRAISIN );
  my %args = ();

  $E->TieBreakMethod('precedence');
  %args = ( 'ranking1' => 'precedence', 'tied' => \@tied );
  is_deeply(
    [ $E->UnTieList(%args) ],
    [qw( CARAMEL RUMRAISIN CHERRY CHOCOLATE STRAWBERRY)],
    'precedence tiebreaker sorted a longer tie into the right order'
  );

  is_deeply(
    [ $E->UnTieList( ranking1 => 'Approval', tied => \@tied ) ],
    [qw( CHERRY CHOCOLATE CARAMEL RUMRAISIN STRAWBERRY)],
    'approval tiebreaker with sub-resolution by precedence'
  );

  is_deeply(
    [
      $E->UnTieList(
        ranking1 => 'Approval',
        tied     =>
          [qw( CARAMEL STRAWBERRY CHOCCHUNK PISTACHIO ROCKYROAD RUMRAISIN )]
      )
    ],
    [qw( ROCKYROAD PISTACHIO CARAMEL RUMRAISIN STRAWBERRY CHOCCHUNK )],
    'another correct sort order of choices per approval then precedence'
  );

  is_deeply(
    [
      $E->UnTieList(
        ranking1 => 'Approval',
        tied     => [ 'CHOCCHUNK', 'STRAWBERRY' ]
      )
    ],
    [qw( STRAWBERRY CHOCCHUNK )],
    'approval resolves 2 choices'
  );

  is_deeply(
    [
      $E->UnTieList(
        ranking1 => 'Approval',
        tied     => [ 'STRAWBERRY', 'CHOCCHUNK' ]
      )
    ],
    [qw( STRAWBERRY CHOCCHUNK )],
    'approval resolved same 2 choices with order switched'
  );

  my %tie =
    map { $_ => 1 } (qw/CHERRY CHOCOLATE CARAMEL RUMRAISIN STRAWBERRY/);
  is_deeply(
    [ $E->UnTieList( ranking1 => 'TopCount', tied => \@tied ) ],
    [qw( CHERRY CHOCOLATE CARAMEL RUMRAISIN STRAWBERRY )],
    'topcount tiebreaker with sub-resolution by precedence'
  );
};

subtest 'UnTieActive' => sub {
  is_deeply(
    [ split /\n/, path( $D->PrecedenceFile() )->slurp() ],
    [ $D->UnTieActive( 'ranking1' => 'precedence' ) ],
    'sort an active list by precedence'
  );
  my $expectTopApp = [
    qw/
      FUDGESWIRL
      VANILLA
      MINTCHIP
      ROCKYROAD
      RUMRAISIN
      PISTACHIO
      CHOCCHUNK
      BUBBLEGUM
      CHOCOLATE
      CHERRY
      STRAWBERRY
      CARAMEL
      /
  ];
  my $expectAppTop = [
    qw/
      MINTCHIP
      BUBBLEGUM
      FUDGESWIRL
      VANILLA
      CHOCOLATE
      CHERRY
      ROCKYROAD
      RUMRAISIN
      PISTACHIO
      CHOCCHUNK
      STRAWBERRY
      CARAMEL
      /
  ];
  my @dtap =
    $D->UnTieActive( 'ranking1' => 'topcount', 'ranking2' => 'approval' );
  my @datp =
    $D->UnTieActive( 'ranking2' => 'topcount', 'ranking1' => 'approval' );
  is_deeply( \@dtap, $expectTopApp,
    'TopCount Approval where choices tied in both' );
  is_deeply( \@datp, $expectAppTop,
    'Approval TopCount where choices tied in both' );
};

done_testing();
