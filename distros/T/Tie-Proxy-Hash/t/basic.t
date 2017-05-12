# (X)Emacs mode: -*- cperl -*-

use strict;

=head1 Unit Test Package for Tie::Proxy::Hash

This package tests the basic utility of Tie::Proxy::Hash

=cut

use Data::Dumper 2.101 qw( Dumper );
use FindBin       1.42 qw( $Bin );
use Test          1.13 qw( ok plan );

use lib $Bin;
use test qw( DATA_DIR
             evcheck );

BEGIN {
  # 1 for compilation test,
  plan tests  => 107,
       todo   => [],
}

# ----------------------------------------------------------------------------

use Tie::Proxy::Hash;

=head2 Test 1: compilation

This test confirms that the test script and the modules it calls compiled
successfully.

=cut

ok 1, 1, 'compilation';

# -------------------------------------

=head2 Tests 2--59: simple use

( 1) check tie %hash, 'Tie::Proxy::Hash' does not throw an exception
( 2) check $hash->add_hash does not throw an exception
( 3) check value of $hash{a} is 1
( 4) check value of $hash{b} is 2
( 5) check $hash->add_hash (again) does not throw an exception
( 6) check value of $hash{b} is 2
( 7) check value of $hash{c} is 4
( 8) check $hash->add_hash (replacing first) does not throw an exception
( 9) check value of $hash{a} is 5
(10) check value of $hash{b} is 3
(11) check value of $hash{b} is 3
(12) check $hash->remove_hash does not throw an exception
(13) check value of $hash{b} is 3
(14) check value of $hash{c} is 4
(15) check that $hash{b} exists
(16) check that $hash{a} does not exist
(17) check $hash->add_hash (again) does not throw an exception
(18) check value of $hash{a} is 1
(19) check value of $hash{b} is 3
(20) check that storing a wholly new value does not throw an exception
(21) check that storing an existing value does not throw an exception
(22) check that storing an existing value does not throw an exception
(23) check value of $hash{a} is 1
(24) check value of $hash{b} is 9
(25) check value of $hash{c} is 8
(26) check value of $hash{d} is 7
(27) check $hash->remove_hash (again) does not throw an exception
(28) check value of $hash{a} is 1
(29) check value of $hash{b} is 2
(30) check value of $hash{c} is undef
(31) check value of $hash{d} is 7
(32) check that deleting $hash{a} throws no exception
(33) check that deleting $hash{c} throws no exception
(34) check that deleting $hash{d} throws no exception
(35) check value of $hash{a} is undef
(36) check value of $hash{b} is undef
(37) check value of $hash{c} is undef
(38) check value of $hash{d} is 7
(39) check that storing a wholly new value does not throw an exception
(40) check $hash->remove_hash (again) does not throw an exception
(41) check value of $hash{a} does not exist
(42) check value of $hash{b} does not exist
(43) check value of $hash{c} does not exist
(44) check value of $hash{d} does not exist
(45) check value of $hash{e} is 11
(46) check $hash->add_hash does not throw an exception
(47) check value of $hash{a} is 1
(48) check value of $hash{b} is 2
(49) check $hash->add_hash (again) does not throw an exception
(50) check value of $hash{b} is 2
(51) check value of $hash{c} is 4
(52) check value of $hash{e} is 11
(53) check C<%hash = ()> does not throw an exception
(54) check value of $hash{a} does not exist
(55) check value of $hash{b} does not exist
(56) check value of $hash{c} does not exist
(57) check value of $hash{d} does not exist
(58) check value of $hash{e} does not exist

=cut

{
  my (%hash, $hash);
  ok(evcheck(sub {;$hash=tie %hash, 'Tie::Proxy::Hash'}, 'simple use ( 1)'),
     1,                                                     'simple use ( 1)');

  ok(evcheck(sub {;$hash->add_hash('bart', +{a=>1,b=>2})}, 'simple use ( 2)'),
     1,                                                     'simple use ( 2)');
  ok $hash{a}, 1,                                           'simple use ( 3)';
  ok $hash{b}, 2,                                           'simple use ( 4)';
  ok(evcheck(sub {;$hash->add_hash('lisa', +{b=>3,c=>4})}, 'simple use ( 5)'),
     1,                                                     'simple use ( 5)');
  ok $hash{b}, 2,                                           'simple use ( 6)';
  ok $hash{c}, 4,                                           'simple use ( 7)';
  ok(evcheck(sub {;$hash->add_hash('bart', +{a=>5,c=>6})}, 'simple use ( 8)'),
     1,                                                     'simple use ( 9)');
  ok $hash{a}, 5,                                           'simple use (10)';
  ok $hash{b}, 3,                                           'simple use (10)';
  ok $hash{c}, 6,                                           'simple use (11)';

  ok(evcheck(sub {;$hash->remove_hash('bart')},  'simple use (12)'),
     1,                                                     'simple use (12)');
  ok $hash{b}, 3,                                           'simple use (13)';
  ok $hash{c}, 4,                                           'simple use (14)';

  ok exists $hash{b};                                      # simple use (15)
  ok ! exists $hash{a};                                    # simple use (16)

  ok(evcheck(sub {;$hash->add_hash('bart', +{a=>1,b=>2})}, 'simple use (17)'),
     1,                                                     'simple use (17)');
  ok $hash{a}, 1,                                           'simple use (18)';
  ok $hash{b}, 3,                                           'simple use (19)';

  ok(evcheck(sub {;$hash{d} = 7},  'simple use (20)'),
     1,                                                     'simple use (20)');
  ok(evcheck(sub {;$hash{c} = 8},  'simple use (21)'),
     1,                                                     'simple use (21)');
  ok(evcheck(sub {;$hash{b} = 9},  'simple use (22)'),
     1,                                                     'simple use (22)');
  ok $hash{a}, 1,                                           'simple use (23)';
  ok $hash{b}, 9,                                           'simple use (24)';
  ok $hash{c}, 8,                                           'simple use (25)';
  ok $hash{d}, 7,                                           'simple use (26)';

  ok(evcheck(sub {;$hash->remove_hash('lisa')},  'simple use (27)'),
     1,                                                     'simple use (27)');
  ok $hash{a}, 1,                                           'simple use (28)';
  ok $hash{b}, 2,                                           'simple use (29)';
  ok $hash{c}, undef,                                       'simple use (30)';
  ok $hash{d}, 7,                                           'simple use (31)';

  ok(evcheck(sub {; delete $hash{a} },  'simple use (32)'),
     1,                                                     'simple use (32)');
  ok(evcheck(sub {; delete $hash{c} },  'simple use (33)'),
     1,                                                     'simple use (33)');
  ok(evcheck(sub {; delete $hash{d} },  'simple use (34)'),
     1,                                                     'simple use (34)');
  ok $hash{a}, undef,                                       'simple use (35)';
  ok $hash{b}, 2,                                           'simple use (36)';
  ok $hash{c}, undef,                                       'simple use (37)';
  ok $hash{d}, undef,                                       'simple use (38)';

  ok(evcheck(sub {;$hash{e} = 11},  'simple use (39)'),
     1,                                                     'simple use (39)');
  ok(evcheck(sub {;$hash->remove_hash('bart')},  'simple use (40)'),
     1,                                                     'simple use (40)');
  ok ! exists $hash{a};                                    # simple use (41)
  ok ! exists $hash{b};                                    # simple use (42)
  ok ! exists $hash{c};                                    # simple use (43)
  ok ! exists $hash{d};                                    # simple use (44)
  ok $hash{e}, 11,                                          'simple use (45)';

  ok(evcheck(sub {;$hash->add_hash('bart', +{a=>1,b=>2})}, 'simple use (46)'),
     1,                                                     'simple use (46)');
  ok $hash{a},  1,                                          'simple use (47)';
  ok $hash{b},  2,                                          'simple use (48)';
  ok(evcheck(sub {;$hash->add_hash('lisa', +{b=>3,c=>4})},  'simple use (49)'),
     1,                                                     'simple use (49)');
  ok $hash{b},  2,                                          'simple use (50)';
  ok $hash{c},  4,                                          'simple use (51)';
  ok $hash{e}, 11,                                          'simple use (52)';

  ok(evcheck(sub {%hash = ()},  'simple use (53)'),
     1,                                                     'simple use (53)');
  ok ! exists $hash{a};                                    # simple use (54)
  ok ! exists $hash{b};                                    # simple use (55)
  ok ! exists $hash{c};                                    # simple use (56)
  ok ! exists $hash{d};                                    # simple use (57)
  ok ! exists $hash{3};                                    # simple use (58)
}

# -------------------------------------

=head2 Tests 60--89: iteration

(     1) check tie %hash, 'Tie::Proxy::Hash' does not throw an exception
(     2) check $hash->add_hash does not throw an exception
(     3) check that storing a wholly new value does not throw an exception
(     4) check $hash->add_hash (again) does not throw an exception
(     5) check that storing a wholly new value does not throw an exception
(     6) check that storing an existing value does not throw an exception
(     7) check that C<keys %hash> does not throw an exception
(     8) check that 4 keys are found
( 9--12) check keys are as expected
(    13) check that C<values %hash> does not throw an exception
(    14) check that 4 values are found
(15--18) check values are as expected
(19--30) check each in list context throws no exception; check key and value
         returned (4 times)

=cut

{
  my (%hash, $hash);
  ok(evcheck(sub {;$hash=tie %hash, 'Tie::Proxy::Hash'}, 'iteration ( 1)'),
     1,                                                      'iteration ( 1)');

  ok(evcheck(sub {;$hash->add_hash('bart', +{a=>1,b=>2})}, 'iteration ( 2)'),
     1,                                                      'iteration ( 2)');
  ok(evcheck(sub {;$hash{c} = 9}, 'iteration ( 3)'),
     1,                                                      'iteration ( 3)');
  ok(evcheck(sub {;$hash->add_hash('lisa', +{b=>3,c=>4})}, 'iteration ( 4)'),
     1,                                                      'iteration ( 4)');
  ok(evcheck(sub {;$hash{d} = 7}, 'iteration ( 5)'),
     1,                                                      'iteration ( 5)');
  ok(evcheck(sub {;$hash{c} = 8}, 'iteration ( 6)'),
     1,                                                      'iteration ( 6)');

  my %ref = (a=>1, b=>2, c=>8, d=>7);
  my @keys;
  ok(evcheck(sub {@keys = keys %hash}, 'iteration ( 7)'),
     1,                                                      'iteration ( 7)');
  ok @keys, keys %ref,                                       'iteration ( 8)';

  ok((sort @keys)[$_], (sort keys %ref)[$_],
                                             sprintf("iteration (%2d)", $_+9))
    for 0..3;

  my @values;
  ok(evcheck(sub {@values = values %hash}, 'iteration (13)'),
     1,                                                      'iteration (13)');
  ok @values, keys %ref,                                     'iteration (14)';
  ok((sort {$a<=>$b} @values)[$_], (sort {$a<=>$b} values %ref)[$_],
                                            sprintf("iteration (%2d)", $_+15))
    for 0..3;

  print STDERR Data::Dumper->Dump([\@keys, \@values, $hash],
                                  [qw( keys values hash )])
    if $ENV{TEST_DEBUG};

  for (0..3) {
    my ($k, $v);
    ok(evcheck(sub {($k, $v) = each %hash},
               sprintf("iteration (%2d)", $_*3+19)),
     1,                                   sprintf("iteration (%2d)", $_*3+19));
    ok $k, $keys[$_],                     sprintf("iteration (%2d)", $_*3+20);
    ok $v, $values[$_],                   sprintf("iteration (%2d)", $_*3+21);
  }
}

# -------------------------------------

=head 90--107: tie args

( 1) Tie to C<%hash>, using tie args to default two hashes (bart and maggie).
     Check no expection thrown.
( 2) Check value a is 1 (in bart).
( 3) Check value b is 2 (in bart).
( 4) Check value c is 6 (in maggie).
( 5) Check value d is undef (in neither).
( 6) Check value e is 10 (in maggie).
( 7) Add hash bart again; check no exception thrown.
( 8) Set value c to 9; check no exception thrown.
( 9) Add hash lisa; check no exception thrown.
(10) Check value c is 9 (in maggie; set in ( 3)).
(11) Check value d is 3 (in lisa).
(12) Set value d to 7; check no exception thrown.
(13) Set value c to 8; check no exception thrown.
(14) Check value a is -1 (in bart; hash reset in ( 2)).
(15) Check value b is 4 (in lisa).
(16) Check value c is 8 (in maggie; set in ( 8)).
(17) Check value d is 7 (in lisa).
(18) Check value e is 10 (in maggie).

=cut

{
  my (%hash, $hash);
  ok(evcheck(sub {
               $hash=tie %hash, 'Tie::Proxy::Hash', (bart   => +{a=>-1,
                                                                 b=>-2} =>
                                                     sub { $_[0] * -1 },
                                                     maggie => +{a=>5,
                                                                 c=>6,
                                                                 e=>10},
                                                    );
             }, 'tie args ( 1)'),
     1,                                                       'tie args ( 1)');
  print STDERR Data::Dumper->Dump([$hash],
                                  [qw( hash )])
    if $ENV{TEST_DEBUG};
  ok $hash{a},  1,                                            'tie args ( 2)';
  ok $hash{b},  2,                                            'tie args ( 3)';
  ok $hash{c},  6,                                            'tie args ( 4)';
  ok $hash{d}, undef,                                         'tie args ( 5)';
  ok $hash{e}, 10,                                            'tie args ( 6)';

  ok(evcheck(sub {;$hash->add_hash('bart', +{a=>-1})}, 'tie args ( 7)'),
     1,                                                       'tie args ( 7)');
  ok(evcheck(sub {;$hash{c} = 9}, 'tie args ( 8)'),
     1,                                                      'tie args ( 8)');
  ok(evcheck(sub {;$hash->add_hash('lisa', +{d=>3,b=>4})}, 'tie args ( 9)'),
     1,                                                      'tie args ( 9)');
  ok $hash{c},  9,                                           'tie args (10)';
  ok $hash{d},  3,                                           'tie args (11)';
  ok(evcheck(sub {;$hash{d} = 7}, 'tie args (12)'),
     1,                                                      'tie args (12)');
  ok(evcheck(sub {;$hash{c} = 8}, 'tie args (13)'),
     1,                                                      'tie args (13)');
  ok $hash{a}, -1,                                           'tie args (14)';
  ok $hash{b},  4,                                           'tie args (15)';
  ok $hash{c},  8,                                           'tie args (16)';
  ok $hash{d},  7,                                           'tie args (17)';
  ok $hash{e}, 10,                                           'tie args (18)';
}

# ----------------------------------------------------------------------------
