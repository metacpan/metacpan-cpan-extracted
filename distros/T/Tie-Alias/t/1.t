# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
BEGIN { use_ok('Tie::Alias') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

our $original = 5;
our %o_hash = ( a=> 1, b=> 2 );
our @o_arr = (3,4,5,6);

my $new_he="beep";
Tie::Alias::alias ((my $alias) => $original, (my $arr_pos_2) => $o_arr[2],
(my $hash_elem_b) => $o_hash{b},  $new_he => $o_hash{c});
ok($alias == $original, 'fetch aliased scalar');
$arr_pos_2++;
ok($arr_pos_2 == $o_arr[2], 'incremented aliased array element ');
$o_arr[2]++;
ok($arr_pos_2 == $o_arr[2], 'still aliased ');


ok($hash_elem_b == $o_hash{b}, 'fetch aliased hash element');
$hash_elem_b = 99;
ok($hash_elem_b == $o_hash{b}, 'fetch aliased hash element');
$o_hash{b} = 'fetch aliased hash element';
ok($hash_elem_b eq $o_hash{b}, 'fetch aliased hash element');

ok((!defined $new_he),'new hash element is not defined');
$new_he = 'boop';
ok(($new_he eq $o_hash{c}), 'new hash element alias aliased.');

tie my %ha, Tie::Alias => \%o_hash;

tie my @ar, Tie::Alias => \@o_arr;


