# (X)Emacs mode: -*- cperl -*-

use strict;

=head1 Unit Test Package for Tie-Proxy-Hash

This package tests the basic utility of Tie-Proxy-Hash

=cut

use FindBin 1.42 qw( $Bin );
use Test    1.13 qw( ok plan );

use lib $Bin;
use test qw( DATA_DIR
             evcheck );

BEGIN {
  # 1 for compilation test,
  plan tests  => 41,
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

=head2 Tests 2--16: translate

( 1) check tie %hash, 'Tie::Proxy::Hash' does not throw an exception
( 2) check $hash->add_hash (bart) does not throw an exception (with a
     translator)
( 3) check value of $hash{a} is 27
( 4) check value of $hash{b} is 24
( 5) check $hash->add_hash (lisa) does not throw an exception (without a
     translator)
( 6) check value of $hash{b} is 24
( 7) check value of $hash{c} is 4
( 8) check $hash->remove_hash (bart) does not throw an exception
( 9) check value of $hash{b} is 3
(10) check value of $hash{c} is 4
(11) check that $hash{b} exists
(12) check that $hash{a} does not exist
(13) check $hash->add_hash (again) does not throw an exception
     (without a translator)
(14) check value of $hash{a} is 1
(15) check value of $hash{b} is 3

=cut

{
  my ($hash, %hash);
  ok(evcheck(sub {$hash=tie %hash, 'Tie::Proxy::Hash'}, 'translate ( 1)'),
     1,                                                      'translate ( 1)');

  ok(evcheck(sub {
               $hash->add_hash('bart', +{a=>1,b=>2}, sub {(9-$_[0].$_[0])/3})
             }, 'translate ( 2)'),
     1,                                                      'translate ( 2)');
  ok $hash{a}, 27,                                           'translate ( 3)';
  ok $hash{b}, 24,                                           'translate ( 4)';

  ok(evcheck(sub {;$hash->add_hash('lisa', +{b=>3,c=>4})}, 'translate ( 5)'),
     1,                                                      'translate ( 5)');
  ok $hash{b}, 24,                                           'translate ( 6)';
  ok $hash{c}, 4,                                            'translate ( 7)';
  ok(evcheck(sub {;$hash->remove_hash('bart')}, 'translate ( 8)'),
     1,                                                      'translate ( 8)');
  ok $hash{b}, 3,                                            'translate ( 9)';
  ok $hash{c}, 4,                                            'translate (10)';

  ok exists $hash{b};                                       # translate (11)
  ok ! exists $hash{a};                                     # translate (12)

  ok(evcheck(sub {;$hash->add_hash('bart', +{a=>1,b=>2})}, 'translate (13)'),
     1,                                                      'translate (13)');
  ok $hash{a}, 1,                                            'translate (14)';
  ok $hash{b}, 3,                                            'translate (15)';
}

# -------------------------------------

=head2 Tests 17--29: tchange

Check the reinstalling a hash whilst inserting/overwriting/eliminating its
translator works

=cut

{
  my ($hash, %hash);
  ok(evcheck(sub {$hash=tie %hash, 'Tie::Proxy::Hash'}, 'tchange ( 1)'),
     1,                                                        'tchange ( 1)');

  ok(evcheck(sub {
               $hash->add_hash('bart', +{a=>1,b=>2})
             }, 'tchange ( 2)'),
     1,                                                        'tchange ( 2)');
  ok $hash{a},  1,                                             'tchange ( 3)';
  ok $hash{b},  2,                                             'tchange ( 4)';

  ok(evcheck(sub {
               $hash->add_hash('bart', +{a=>1,b=>2}, sub {(9-$_[0].$_[0])/3})
             }, 'tchange ( 5)'),
     1,                                                        'tchange ( 5)');
  ok $hash{a}, 27,                                             'tchange ( 6)';
  ok $hash{b}, 24,                                             'tchange ( 7)';

  ok(evcheck(sub {
               $hash->add_hash('bart', +{a=>1,b=>2}, sub {(9-$_[0].$_[0])/9})
             }, 'tchange ( 8)'),
     1,                                                        'tchange ( 8)');
  ok $hash{a},  9,                                             'tchange ( 9)';
  ok $hash{b},  8,                                             'tchange (10)';

  ok(evcheck(sub {
               $hash->add_hash('bart', +{a=>3,b=>4})
             }, 'tchange (11)'),
     1,                                                        'tchange (11)');
  ok $hash{a},  3,                                             'tchange (12)';
  ok $hash{b},  4,                                             'tchange (13)';
}

# -------------------------------------

=head2 Tests 30--41: tstore

Store a value (that would be) in a translated hash; check the hash key is
wiped, and the value stored in the default hash.

=cut

{
  my ($hash, %hash);
  ok(evcheck(sub {$hash=tie %hash, 'Tie::Proxy::Hash'}, 'tstore ( 1)'),
     1,                                                         'tstore ( 1)');

  my $href = +{a=>1,b=>2};
  ok(evcheck(sub {
               $hash->add_hash('bart', $href, sub {(9-$_[0].$_[0])/3})
             }, 'tstore ( 2)'),
     1,                                                         'tstore ( 2)');

  ok $hash{a}, 27,                                              'tstore ( 3)';
  ok $hash{b}, 24,                                              'tstore ( 4)';
  ok evcheck(sub { $hash{b} = 7 }, 'tstore ( 5)'), 1,           'tstore ( 5)';

  ok $hash{a}, 27,                                              'tstore ( 6)';
  ok $hash{b},  7,                                              'tstore ( 7)';
  ok ! exists $href->{b};                                      # tstore ( 8)

   ok(evcheck(sub { $hash->remove_hash('bart') }, 'tstore ( 8)'),
      1,                                                        'tstore ( 9)');

  ok ! exists $hash{a};                                        # tstore (10)
  ok exists $hash{b};                                          # tstore (11)
  ok $hash{b},  7,                                              'tstore (12)';
}


# ----------------------------------------------------------------------------
