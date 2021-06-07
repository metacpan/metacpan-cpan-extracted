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

package TestN {
  use Moose;
  extends 'Vote::Count::Charge';
  use namespace::autoclean;
  with 'Vote::Count::Helper::NthApproval';
  __PACKAGE__->meta->make_immutable;
};

use Vote::Count::ReadBallots 'read_ballots', 'read_range_ballots';

use feature qw /postderef signatures/;
no warnings 'experimental';

  my $B =
    TestN->new(
      Seats     => 2,
      BallotSet => read_ballots('t/data/data2.txt'),
      VoteValue => 100,
    );
  is_deeply(
    [ sort ( $B->NthApproval() ) ],
    [ qw( CARAMEL PISTACHIO ROCKYROAD RUMRAISIN STRAWBERRY ) ],
    'returned list to eliminate'
  );
  my $C =
    TestN->new(
      Seats     => 3,
      BallotSet => read_ballots('t/data/data2.txt'),
      VoteValue => 100,
    );
  is_deeply(
    [ sort ( $C->NthApproval() ) ],
    [ qw( CARAMEL ROCKYROAD RUMRAISIN ) ],
    'another choice had approval == Nth place topcount'
  );

done_testing();