#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

my @subroutines = qw(TIESCALAR STORE FETCH UNTIE on_error register _type _check _get_regex);

require_ok('Tie::CheckVariables');
can_ok('Tie::CheckVariables',@subroutines);

tie my $scalar,'Tie::CheckVariables','integer';
$scalar = 99;
ok($scalar == 99);

my $new_value = -300000;
$scalar = $new_value;
ok($scalar == $new_value);

eval{
  $scalar = 'a';
};
ok($@ ne '');

untie $scalar;

tie my $string,'Tie::CheckVariables','string';
$string = 'test';
ok($string eq 'test');
untie $string;

done_testing();
