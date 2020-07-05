#!/usr/bin/env perl

use 5.022;
# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
use Test::Exception;
use Data::Printer;

use Path::Tiny;

use Vote::Count;
use Vote::Count::ReadBallots 'read_ballots', 'read_range_ballots';
use Vote::Count::RankCount;

use feature qw/signatures postderef/;

# my $VC1 = Vote::Count->new( ballotset => read_ballots('t/data/data2.txt'), );

# my $tc1       = $VC1->TopCount();
my %set1 = (
  CARAMEL    => 0,
  CHOCOLATE  => 1,
  MINTCHIP   => 5,
  PISTACHIO  => 2,
  ROCKYROAD  => 0,
  RUMRAISIN  => 0,
  STRAWBERRY => 1,
  VANILLA    => 7
);
my %tiedset = (
  CARAMEL    => 11,
  CHOCOLATE  => 1,
  MINTCHIP   => 5,
  PISTACHIO  => 2,
  ROCKYROAD  => 0,
  RUMRAISIN  => 0,
  STRAWBERRY => 11,
  VANILLA    => 7
);

my $counted1 = Vote::Count::RankCount->Rank( \%set1 );
my $tied1    = Vote::Count::RankCount->new( \%tiedset );
my $brexit =
  Vote::Count->new( BallotSet => read_ballots('t/data/brexit1.txt'), );

# p $counted1;
isa_ok(
  $counted1,
  ['Vote::Count::RankCount'],
  'Made a new counted object from rank'
);

#   isa_ok($x, ['Vote::Count::TopCount::Rank'],
#     '->RankTopCount generated object of Vote::Count::TopCount::Rank');
can_ok(
  $counted1,
  [qw/ RawCount HashWithOrder HashByRank ArrayTop ArrayBottom/],
  "have expected subs"
);

my $counted1raw = $counted1->RawCount();
is_deeply( \%set1, $counted1raw,
'the RawCount Method should return the same hash as was used to create the Rank object'
);

my $counted1ordered = $counted1->HashWithOrder();
is( $counted1ordered->{'VANILLA'}, 1 );

subtest 'HashByRank' => sub {
  my $counted1byrank = $counted1->HashByRank();
  is_deeply( $counted1byrank->{3}, ['PISTACHIO'],
    'check an element from hashbyrank' );
  is_deeply(
    [ sort( $counted1byrank->{4}->@* ) ],
    [ 'CHOCOLATE', 'STRAWBERRY' ],
    'check a different element that returns more than 1 value'
  );
};

# always sort so we don't care if deeply cares about order.
# p $counted1;
my $counted1top    = $counted1->ArrayTop();
my $leader1        = $counted1->Leader();
my $tieresult1     = $tied1->Leader();
my $counted1bottom = $counted1->ArrayBottom();

is_deeply( $counted1top, ['VANILLA'], "confirm top element" );
is_deeply(
  $counted1bottom,
  [qw( CARAMEL ROCKYROAD RUMRAISIN )],
  "confirm bottom elements"
);
is( $leader1->{'winner'}, 'VANILLA',
  'Leader Method returned top element as winner' );
is( $leader1->{'tie'}, 0, 'Leader Method tie is false on data with winner' );

is( $tieresult1->{'winner'},
  '', 'Leader Method returned empty winner for set with tie' );
is( $tieresult1->{'tie'}, 1, 'Leader Method tie is true for set with tie' );

# p $counted1;
my $table  = $counted1->RankTable();
my $xtable = << 'XTABLE1';
| Rank | Choice     | Votes |
|------|------------|-------|
| 1    | VANILLA    | 7     |
| 2    | MINTCHIP   | 5     |
| 3    | PISTACHIO  | 2     |
| 4    | CHOCOLATE  | 1     |
| 4    | STRAWBERRY | 1     |
| 5    | CARAMEL    | 0     |
| 5    | ROCKYROAD  | 0     |
| 5    | RUMRAISIN  | 0     |
XTABLE1

is( $table, $xtable, 'Generate a table with ->RankTable()' );

is( $counted1->CountVotes(), 16, 'CountVotes method' );

my $bigtie = {
  'GOLD'   => 7,
  'SILVER' => 7,
  'COPPER' => 5,
  'PEARL'  => 5,
  'RUBY'   => 5,
  'BRASS'  => 5,
  'BRONZE' => 5,
};

my $bt  = Vote::Count::RankCount->Rank($bigtie);
my $bto = $bt->HashByRank();
is_deeply(
  $bto->{2},
  [qw/ BRASS BRONZE COPPER PEARL RUBY/],
  'Check that the arrayref from HashByRank is sorted.'
);

subtest 'Bigger Than 10' => sub {

  my $longtable = << 'LONGTABLE';
| Rank | Choice    | Votes |
|------|-----------|-------|
| 1    | LV_TORY   | 186   |
| 2    | LV_LAB    | 183   |
| 3    | REM_LIB   | 180   |
| 4    | REM_TORY  | 176   |
| 5    | REM_LAB   | 173   |
| 6    | LV_LIB    | 170   |
| 7    | SOFT_TORY | 155   |
| 8    | SOFT_LAB  | 154   |
| 9    | SOFT_LIB  | 153   |
| 10   | IND_LCL1  | 91    |
| 11   | IND_LCL2  | 75    |
LONGTABLE

  my $bbyrank = $brexit->Approval()->HashByRank();
  is_deeply( $bbyrank->{10}, ['IND_LCL1'],
    'check tenth element from hashbyrank' );
  is_deeply( $bbyrank->{11}, ['IND_LCL2'],
    'check 11th element from hashbyrank' );
  is_deeply( $bbyrank->{3}, ['REM_LIB'],
    'check 3rd element from hashbyrank' );
  # note $brexit->Approval->RankTable();
  is( $brexit->Approval->RankTable(),
    $longtable, 'Check a long table (sorting with more than 10 choices)' );
};

done_testing();
