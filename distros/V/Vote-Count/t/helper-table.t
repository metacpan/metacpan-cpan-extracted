#!/usr/bin/env perl

use 5.024;
# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
# use Test::Exception;
# use Data::Dumper;

use Path::Tiny;
use Try::Tiny;
use Storable 'dclone';

use Vote::Count::Charge;
use Vote::Count::ReadBallots 'read_ballots', 'read_range_ballots';
use Vote::Count::Helper::Table 'WeightedTable', 'ChargeTable';

use feature qw /postderef signatures/;
no warnings 'experimental';


subtest 'WeightedTable' => sub {
  my $B =
    Vote::Count::Charge->new(
      Seats     => 2,
      BallotSet => read_ballots('t/data/data2.txt'),
      VoteValue => 100,
    );
my $expectable = q(| Rank | Choice     | Votes | VoteValue | Approval | Approval Value |
|:-----|:-----------|------:|----------:|---------:|---------------:|
| 1    | VANILLA    |  7.00 |       700 |    10.00 |           1000 |
| 2    | MINTCHIP   |  5.00 |       500 |     8.00 |            800 |
| 3    | PISTACHIO  |  2.00 |       200 |     2.00 |            200 |
| 4    | CHOCOLATE  |  1.00 |       100 |     8.00 |            800 |
| 5    | CARAMEL    |  0.00 |         0 |     1.00 |            100 |
| 5    | ROCKYROAD  |  0.00 |         0 |     2.00 |            200 |
| 5    | RUMRAISIN  |  0.00 |         0 |     1.00 |            100 |
| 5    | STRAWBERRY |  0.00 |         0 |     5.00 |            500 |
);
  is( WeightedTable($B), $expectable, 'generated table with top and approval counts' );
};

done_testing();