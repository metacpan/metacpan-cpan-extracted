#!/usr/bin/env perl

use 5.024;

# Using Test2, important to specify which version of Test2
# since later versions may break things.

use Test2::V0;
use Test2::Bundle::More;
use Test::Exception;
# use JSON::MaybeXS qw/encode_json/;
# use YAML::XS;
use feature qw /postderef signatures/;
no warnings 'experimental', 'exiting';
# use Path::Tiny;
use Vote::Count::Method::WIGM;
use Vote::Count::ReadBallots 'read_ballots';
use Test2::Tools::Exception qw/dies lives/;
use Test2::Tools::Warnings qw/warns warning warnings no_warnings/;
use Data::Dumper;

my $A = Vote::Count::Method::WIGM->new(
  Seats     => 3,
  VoteValue => 1000,
  BallotSet => read_ballots('t/data/data1.txt')
);

subtest 'A data1' => sub {
  for (qw( ROCKYROAD RUMRAISIN STRAWBERRY )) { $A->Defeat($_) }
  is( $A->_SetWIGQuota, 3000, 'Set the WIG Quota at 3000 for A' );
  my $AR1 = $A->_WIGRound( $A->_SetWIGQuota );
  is_deeply(
    $AR1->{pending},
    [ 'MINTCHIP', 'VANILLA' ],
    'A two choices meet quota round 1'
  );
  is_deeply(
    $AR1->{winvotes},
    { 'MINTCHIP' => 5000, 'VANILLA' => 3000 },
    'Check the votes for those 2 choices'
  );
  is( $AR1->{quota}, 3000, 'verify the expected quota' );
  my $chrg = $A->Charge( 'MINTCHIP', $AR1->{'quota'} );
  $A->_WIGElect($chrg);
  is_deeply(
    $A->GetChoiceStatus('MINTCHIP'),
    { votes => 3000, state => 'elected' },
    '_WIGElect updates $choice_status for mintchip'
  );
  is( $A->GetActive()->{'MINTCHIP'},
    undef, 'MINTCHIP was removed from active by Elect method' );
  $A->_WIGElect( $A->Charge( 'VANILLA', $AR1->{'quota'} ) );
  is_deeply(
    $A->GetChoiceStatus('VANILLA'),
    { votes => 3000, state => 'elected' },
    '_WIGElect updates $choice_status for VANILLA'
  );
};

sub round ( $number, $divisorplaces, $roundplaces ) {
  my $divisor = 10**$divisorplaces;
  my $rounder = 10**$roundplaces;
  # my $new = int ( $number / $divisor ;
  my $new = $number / ( $divisor / $rounder );
  $new += .5;
  return int($new) / $rounder;
}

subtest 'C Scotland2017 Dumbarton' => sub {
  my $C = Vote::Count::Method::WIGM->new(
    Seats     => 4,
    BallotSet => read_ballots('t/data/Scotland2017/Dumbarton.txt')
  );
  my $quota = $C->_SetWIGQuota();

  my $ROUND = $C->_WIGRound($quota);
  is_deeply(
    $ROUND->{pending},
    [ 'David_MCBRIDE_Lab', 'Karen_CONAGHAN_SNP' ],
    'C two choices meet quota round 1'
  );
  is_deeply(
    $ROUND->{winvotes},
    { 'David_MCBRIDE_Lab' => 176200000, 'Karen_CONAGHAN_SNP' => 149900000 },
    'Check the votes for those 2 choices'
  );
  is( $ROUND->{quota}, 131300000, 'verify the expected quota' );
  for my $pending ( 'David_MCBRIDE_Lab', 'Karen_CONAGHAN_SNP' ) {
    my $chrg = $C->Charge( $pending, $quota );
    $C->_WIGElect($chrg);
  }
  my $cntdist1 = $C->TopCount()->RawCount();
  is( round( $cntdist1->{'Iain_MCLAREN_SNP'}, 5, 2 ),
    989.76, 'After Transfer Iain_MCLAREN_SNP rounds to 989.76' );
  is( round( $cntdist1->{'George_BLACK_WDCP'}, 5, 2 ),
    827.13, 'After Transfer George_BLACK_WDCP rounds to 827.13' );

  $ROUND = $C->_WIGRound($quota);
  is( $ROUND->{allvotes}{'Andrew_MUIR_Ind'},
    17090994, "Check the votes for choice that will be defeated" );

  my $abandoned = undef;
  $abandoned = $C->CountAbandoned();
  is( int round( $abandoned->{'value_abandoned'}, 5, 2 ),
    int 52.64,
    'value_abandoned should match at this point to stage 3.' );

  $C->Defeat('Andrew_MUIR_Ind');

  $ROUND = $C->_WIGRound($quota);
  is( $ROUND->{allvotes}{ $ROUND->{lowest} },
    88829800, "Check the votes for choice that will be defeated" );

  $abandoned = $C->CountAbandoned();
  is( int round( $abandoned->{'value_abandoned'}, 5, 2 ),
    int 102.58,
    'Round 4: value_abandoned should match at this point to stage 3.' );
  # note( Dumper $ROUND);

  $C->Defeat( $ROUND->{lowest} );
  $ROUND = $C->_WIGRound($quota);
  is( $ROUND->{lowest}, 'Elizabeth_RUINE_Lab',
    "Round 4: correct choice identified as lowest" );

  $abandoned = $C->CountAbandoned();
  is( int round( $abandoned->{'value_abandoned'}, 5, 2 ),
    int 431.19,
    'Round 3: value_abandoned should match the final non-continuing total.' );

  $C->Defeat( $ROUND->{lowest} );
  $ROUND = $C->_WIGRound($quota);
  is( $ROUND->{'round'}, 5,
    'Round 5: _WIGRound is numbering rounds as expected' );
  is_deeply(
    $ROUND->{allvotes},
    {
      'Iain_MCLAREN_SNP' => 140295782,
      'Brian_WALKER_Con' => 138798862
    },
    'Round 5: 2 choices remain, verify allvotes'
  );
  is_deeply( $ROUND->{'allvotes'}, $ROUND->{'winvotes'},
    'Round 5: because all remaining choices are elected, allvotes == winvotes'
  );
  is_deeply(
    $ROUND->{'pending'},
    [ 'Iain_MCLAREN_SNP', 'Brian_WALKER_Con' ],
    'Round 5: Final two choices are in the pending key'
  );

  for my $c (qw( Iain_MCLAREN_SNP Brian_WALKER_Con)) {
    $C->Elect($c);
    $C->SetChoiceStatus( $c, { votes => $ROUND->{'allvotes'}{$c} } );
  }
  is_deeply(
    [ $C->Elected() ],
    [
      qw( David_MCBRIDE_Lab Karen_CONAGHAN_SNP Iain_MCLAREN_SNP Brian_WALKER_Con)
    ],
    'Elected() returns list in correct order'
  );

  # note( Dumper $ROUND);
  # note( Dumper $C->GetChoiceStatus() );
  # $C->ResetActive();
  my @fullchoices = $C->GetChoices;
  push @fullchoices, 'NONE';
  $C->SetActiveFromArrayRef( \@fullchoices );
  # note( Dumper $C->TopCount()->RankTable() );

  $C->WriteLog();
  $C->WriteSTVEvent();
};

# Expected results for C Scotland2017 Dumbarton
# name                      stage1  stage2  stage3  stage4  stage5
#                           round1  ------  round2  round3  round4  round5
#   BLACK, George (WDCP)       792  821.05  827.13  888.30    0.00  0
#   CONAGHAN, Karen (SNP)     1499 1499.00 1313.00 1313.00 1313.00  1313
#   MCBRIDE, David (Lab)      1762 1313.00 1313.00 1313.00 1313.00  1313
#   MCLAREN, Iain (SNP)        809  827.09  989.76  998.64 1254.05  1402
#   MUIR, Andrew (Ind)         159  168.43  170.91    0.00    0.00  0
#   RUINE, Elizabeth (Lab)     584  910.17  915.01  937.18 1103.63  0
#   WALKER, Brian (Con)        957  979.68  980.55 1009.31 1147.13  1388
#   non-transferable             0   43.58   52.64  102.58  431.19
# ROUND5: Vote::Count transfers after eliminating last choice before
# checking seats vs choices.

done_testing();
