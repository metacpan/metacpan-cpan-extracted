#!/usr/bin/env perl

use 5.024;
# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
# use Test::Exception;
# use Data::Dumper;

# use Path::Tiny;
# use Try::Tiny;
# use Storable 'dclone';

use Vote::Count;
use Vote::Count::ReadBallots 'read_ballots', 'read_range_ballots';
use Vote::Count::Helper::FullCascadeCharge;

use feature qw /postderef signatures/;
no warnings 'experimental';

  my $H = read_ballots 't/data/data2.txt' ;
  my $cost = { 'MINTCHIP' => 75, 'VANILLA' => 54 };
  my $active = { 'CHOCOLATE' => 1, 'STRAWBERRY' => 1, 'PISTACHIO' => 1, 'ROCKYROAD' => 1, 'CARAMEL' => 1, 'RUMRAISIN' => 1};
  my $crg1 = FullCascadeCharge(
            $H->{'ballots'}, 375, $cost, $active, 100);
  my $chk1 = {
      'VANILLA' => {
        'count' => 7,
        'value' => 378,
        'surplus' => 3
      },
      'MINTCHIP' => {
          'surplus' => 0,
          'value' => 375,
          'count' => 5
        }
      };
  is_deeply( $crg1, $chk1, 'two quota choices first round charge ok' );
  delete $active->{'CHOCOLATE'};

  $cost = { 'MINTCHIP' => 75, 'VANILLA' => 54, 'CHOCOLATE' => 100 };

  my $crg2 = FullCascadeCharge(
            $H->{'ballots'}, 375, $cost, $active, 100);
  my $chk2 = {
      'VANILLA' => {
        'count' => 7,
        'value' => 378,
        'surplus' => 3
      },
      'MINTCHIP' => {
          'surplus' => 0,
          'value' => 375,
          'count' => 5
        },
      'CHOCOLATE' => {
          'surplus' => -45,
          'value' => 330,
          'count' => 6
        }
      };
  is_deeply( $crg2, $chk2, 'same with additional choice under quota' );
  my $valelect = 0;
  for ( 'VANILLA', 'MINTCHIP', 'CHOCOLATE' ) {
      $valelect += $crg2->{$_}{'value'} };
  my $valremain = 0 ;
  for my $k ( keys $H->{'ballots'}->%* ) {
    $valremain +=
      $H->{'ballots'}{$k}{'votevalue'} * $H->{'ballots'}{$k}{'count'};
  }
  is( $valremain + $valelect, 1500,
    'sum of elected value plus remaining value matches total vote value');
  is( $H->{'ballots'}{'CHOCOLATE:MINTCHIP:VANILLA'}{'votevalue'}, 0,
    'remaining value on an exhausted ballot is 0');

done_testing();