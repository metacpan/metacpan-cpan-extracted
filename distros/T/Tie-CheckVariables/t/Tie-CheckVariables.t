# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Tie-CheckVariables.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;

my @subroutines = qw(TIESCALAR STORE FETCH DESTROY UNTIE on_error register _type _regex _get_regex);

require_ok('Tie::CheckVariables');
can_ok('Tie::CheckVariables',@subroutines);


Tie::CheckVariables->on_error(sub{ die;});

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
