use Test::Given;
use strict;
use warnings;

my @steps = ();
sub step($) { push @steps, @_ }

describe 'Order in nested contexts' => sub {
  Given sub { step 'GA' };
  And  sub { step 'ga' };
  When sub { step 'WA' };
  And  sub { step 'wa' };
  Invariant sub { step 'IA' };
  And sub { step 'ia' };
  Then sub { step 'TA' };
  And sub { step 'ta' };
  context 'Nested 1' => sub {
    Given sub { step 'GB' };
    And  sub { step 'gb' };
    When sub { step 'WB' };
    And  sub { step 'wb' };
    Invariant sub { step 'IB' };
    And sub { step 'ib' };
    Then sub { step 'TB' };
    And  sub { step 'tb' };
    context 'Level 2' => sub {
      Given sub { step 'GC' };
      And   sub { step 'gc' };
      When sub { step 'WC' };
      And  sub { step 'wc' };
      Invariant sub { step 'IC' };
      And sub { step 'ic' };
      Then sub { step 'TC' };
      And  sub { step 'tc' };
      onDone sub { step 'DC' };
      And sub { step 'dc' };
    };
    onDone sub { step 'DB' };
    And sub { step 'db' };
  };
  context 'Level 1 again' => sub {
    Given sub { step 'GD' };
    And   sub { step 'gd' };
    When sub { step 'WD' };
    And  sub { step 'wd' };
    Invariant sub { step 'ID' };
    And sub { step 'id' };
    Then sub { step 'TD' };
    And  sub { step 'td' };
    onDone sub { step 'DD' };
    And sub { step 'dd' };
  };
  onDone sub { step 'DA' };
  And sub { step 'da' };
};
onDone sub { print '### ORDER:', join(',', @steps) };
