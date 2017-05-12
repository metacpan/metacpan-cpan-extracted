# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Object-Collection.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

#use Test::More 'no_plan';    #tests => 'noplan';
use Test::More tests => 14;
use Data::Dumper;

BEGIN {
    use_ok('Tie::UnionHash');
}
my %hash1 = ( 1 => 1, 3 => 3 );
my %hash2 = ( 2 => 2, 3 => 3 );
my %hashu;
tie %hashu, 'Tie::UnionHash', \%hash1, \%hash2, 'freeze_keys' ;
is_deeply( [ keys %hashu ], [ '1', '2', '3' ], "Check keys" );
$hashu{4} = 4;
ok( exists $hashu{4}, "check exists key:4" );
ok( !exists $hashu{5}, "check not exists key:5" );
is_deeply(
    \%hash1,
    {
        '1' => 1,
        '3' => 3,
    },
    "check orig first hash after write  new key"
);
is_deeply(
    \%hash2,
    {
        '4' => 4,
        '3' => 3,
        '2' => 2
    },
    "check write new key"
);
is_deeply(
    \%hashu,
    {
        '1' => 1,
        '2' => 2,
        '3' => 3,
        '4' => 4
    },
    "Check union hash after write key"
);

$hashu{3} = 4;

is_deeply(
    \%hashu,
    {
        '1' => 1,
        '2' => 2,
        '3' => 4,
        '4' => 4
    },
    "check set dublicated key in hashes"
);
delete $hashu{3};

is_deeply \%hash1,
  {
    '1' => 1,
    '3' => 4
  },
  "delete: check first hash";
is_deeply \%hash2,
  {
    '4' => 4,
    '2' => 2
  },
  "delete: check last hash";
is_deeply \%hashu,
  {
    '1' => 1,
    '2' => 2,
    '3' => 4,
    '4' => 4
  },
  "delete: check union hash";

%hashu = ();

is_deeply \%hash1,
  {
    '1' => 1,
    '3' => 4
  },
  "clean: check first";
is_deeply \%hash2, {}, "clean check second hash";
is_deeply \%hashu,
  {
    '1' => 1,
    '3' => 4
  },
  "clean: check union hash";

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

