#!/usr/bin/env perl

use 5.022;
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

subtest 'UnTieList' => sub {
  my $E = Vote::Count->new(
    BallotSet                    => read_ballots('t/data/ties1.txt'),
    TieBreakMethod               => 'approval',
    PrecedenceFile               => 't/data/tiebreakerprecedence1.txt',
    TieBreakerFallBackPrecedence => 1,
  );

  my @tied = qw( CARAMEL STRAWBERRY CHOCCHUNK PISTACHIO ROCKYROAD RUMRAISIN );
  my @untied = $E->UnTieList( 'Approval', @tied );
  my @expect =
    qw( ROCKYROAD PISTACHIO CARAMEL RUMRAISIN STRAWBERRY CHOCCHUNK );
  is_deeply( \@untied, \@expect,
    'correct sort order of choices per approval then precedence' );

  @untied = $E->UnTieList( 'precedence', @tied );
  @expect = qw( PISTACHIO ROCKYROAD CARAMEL RUMRAISIN CHOCCHUNK STRAWBERRY);
  is_deeply( \@untied, \@expect,
    'correct sort order of choices per precedence only' );
  $E->{'BallotSet'}{'ballots'}{'STRAWBERRY'} = {
    count     => 2,
    votevalue => .2,
    votes     => ["STRAWBERRY"]
  };
  @untied = $E->UnTieList( 'Approval', @tied );
  @expect = qw( ROCKYROAD STRAWBERRY PISTACHIO CARAMEL RUMRAISIN CHOCCHUNK );
  is_deeply( \@untied, \@expect,
    'modified order when fractional vote is added to a choice' );
};

subtest 'UntieActive' => sub {
  my $D = Vote::Count->new(
    BallotSet                    => read_ballots('t/data/ties1.txt'),
    TieBreakerFallBackPrecedence => 1,
    PrecedenceFile               => 't/data/tiebreakerprecedence1.txt',
  );

  my $var2 = {
    FUDGESWIRL => 1,
    VANILLA    => 2,
    MINTCHIP   => 3,
    ROCKYROAD  => 4,
    PISTACHIO  => 5,
    RUMRAISIN  => 6,
    BUBBLEGUM  => 7,
    CHOCCHUNK  => 8,
    CHERRY     => 9,
    CHOCOLATE  => 10,
    CARAMEL    => 11,
    STRAWBERRY => 12,
  };
  subtest 'TopCount approval precedence' => sub {
    my $untied = eval { $D->UntieActive( 'TopCount', 'Approval' ) };
    for my $x ( sort keys %{$var2} ) {
      is( abs( $untied->RawCount()->{$x} ), $var2->{$x}, $x );
    }
  };

  my $var3 = {
    MINTCHIP   => 1,
    FUDGESWIRL => 2,
    VANILLA    => 3,
    BUBBLEGUM  => 4,
    CHERRY     => 5,
    CHOCOLATE  => 6,
    ROCKYROAD  => 7,
    PISTACHIO  => 8,
    RUMRAISIN  => 9,
    CARAMEL    => 10,
    STRAWBERRY => 11,
    CHOCCHUNK  => 12,
  };

  subtest 'Borda topcount precedence' => sub {
    my $untied = $D->UntieActive( 'Borda', 'TopCount' );
    for my $x ( sort keys %{$var3} ) {
      is( abs( $untied->RawCount()->{$x} ), $var3->{$x}, $x );
    }
  };

  my %var4 = do {
      my $ctr = 0;
      map { $_ => ++$ctr } ( split /\n/, path('t/data/tiebreakerprecedence1.txt')->slurp );
    };
    my $prec = $D->UntieActive( 'Precedence' );
    is_deeply( $prec->HashWithOrder(), \%var4,
      'UntieActive hashwithorder matches the raw precedence file');
  delete $D->{'Active'}{'FUDGESWIRL'};
  delete $D->{'Active'}{'VANILLA'};
  my $afterelim = $D->UntieActive( 'TopCount', 'Approval' )->HashByRank();
  is( scalar( keys $afterelim->%* ), 10,
    'With 2 choices eliminated UntieActive had 2 fewer choices');
  is( $afterelim->{1}[0], 'CHERRY', 'new leader after the eliminations');
  is( $afterelim->{2}[0], 'MINTCHIP', 'check a choice that moved down rank after elimination' );
};

done_testing;