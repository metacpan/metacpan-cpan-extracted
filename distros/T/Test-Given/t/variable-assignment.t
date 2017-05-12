use Test::Given;
require 't/test_helper.pl';
use strict;
use warnings;

our ($given_bareword, $when_bareword, $given_string, $when_string, $given_scalar, $when_scalar, @given_array, @when_array, %given_hash, %when_hash);
our ($bareword, $string, $scalar, $array, $hash, $sub);

my $true = sub { 1 };

describe 'Given and When create variables' => sub {
  context 'Given/When with bareword' => sub {
    Given bareword => $true;
    Given given_bareword => sub { 'foo' };
    When when_bareword => sub { 'bar' };
    Then sub { $given_bareword eq 'foo' };
    And sub { $when_bareword eq 'bar' };
  };
  context 'Given/When with string' => sub {
    Given string => $true;
    Given 'given_string' => sub { 'foo' };
    When 'when_string' => sub { 'bar' };
    Then sub { $given_string eq 'foo' };
    And sub { $when_string eq 'bar' };
  };
  context 'Given/When with scalar' => sub {
    Given scalar => $true;
    Given '$given_scalar' => sub { 'foo' };
    When '$when_scalar' => sub { 'bar' };
    Then sub { $given_scalar eq 'foo' };
    And sub { $when_scalar eq 'bar' };
  };
  context 'Given/When with array' => sub {
    Given array => $true;
    Given '@given_array' => sub { (1,2,3) };
    When '@when_array' => sub { (7,8,9) };
    Then sub { join(',', @given_array) eq '1,2,3' };
    And sub { join(',', @when_array) eq '7,8,9' };
  };
  context 'Given/When with hash' => sub {
    Given hash => $true;
    Given '%given_hash' => sub { (a=>1, b=>2); };
    When '%when_hash' => sub { (x=>8, y=>9) };
    Then sub { join(',', sort keys %given_hash) eq 'a,b' };
    And sub { join(',', sort keys %when_hash) eq 'x,y' };
  };
  context 'Given/When with codref' => sub {
    Given sub => $true;
    Given '&given_sub' => sub { sub { "foo@_" } };
    When '&when_sub' => sub { sub { "bar@_" } };
    Then sub { given_sub('baz') eq 'foobaz' };
    And sub { when_sub('baz') eq 'barbaz' };
  };
  Invariant sub { is_set_only_if($bareword, $given_bareword) };
  Invariant sub { is_set_only_if($bareword, $when_bareword) };
  Invariant sub { is_set_only_if($string, $given_string) };
  Invariant sub { is_set_only_if($string, $when_string) };
  Invariant sub { is_set_only_if($scalar, $given_scalar) };
  Invariant sub { is_set_only_if($scalar, $when_scalar) };
  Invariant sub { is_set_only_if($array, \@given_array) };
  Invariant sub { is_set_only_if($array, \@when_array) };
  Invariant sub { is_set_only_if($hash, \%given_hash) };
  Invariant sub { is_set_only_if($hash, \%when_hash) };
  Invariant sub { is_set_only_if($sub, \&given_sub) };
  Invariant sub { is_set_only_if($sub, \&when_sub) };
  Then sub { 'nothing defined' };
};

sub is_set_only_if {
  my ($set, $value) = @_;
  my $is_set = !!$value;
  if ( ref $value eq 'ARRAY' ) {
    $is_set = scalar @$value;
  }
  elsif ( ref $value eq 'HASH' ) {
    $is_set = scalar keys %$value;
  }
  elsif ( ref $value eq 'CODE' ) {
    $is_set = defined(&{$value});
  }
  return $set ? $is_set : !$is_set;
}
