# Check different ways of labeling values

use strict;
use warnings;

use Test::More;
use Test::Builder::Tester;

use Test::Group;
use Test::Group::Foreach;


my @equiv_groups = (
{
  p => [ 'one' ],
  a => [ [one => 'one'] ],
},
{
  pp => [ 'two1', 'two2' ],
  ap => [ [two1 => 'two1'], 'two2' ],
  pa => [ 'two1', [two2 => 'two2'] ],
  ab => [ [two1 => 'two1'], [two2 => 'two2'] ],
  aa => [ [two1 => 'two1', two2 => 'two2'] ],
},
{
  ppp => [ 'three1',             'three2',             'three3' ],

  app => [ [three1 => 'three1'], 'three2',             'three3'             ],
  pap => [ 'three1',             [three2 => 'three2'], 'three3'             ],
  ppa => [ 'three1',             'three2',             [three3 => 'three3'] ],

  pab => [ 'three1',             [three2 => 'three2'], [three3 => 'three3'] ],
  apb => [ [three1 => 'three1'], 'three2',             [three3 => 'three3'] ],
  abp => [ [three1 => 'three1'], [three2 => 'three2'], 'three3'             ],

  abc => [ [three1 => 'three1'], [three2 => 'three2'], [three3 => 'three3'] ],

  aab => [ [three1 => 'three1', three2 => 'three2'], [three3 => 'three3'] ],
  aap => [ [three1 => 'three1', three2 => 'three2'], 'three3'             ],

  abb => [ [three1 => 'three1'], [three2 => 'three2', three3 => 'three3'] ],
  pbb => [ 'three1',             [three2 => 'three2', three3 => 'three3'] ],
    
  aaa => [ [three1 => 'three1', three2 => 'three2', three3 => 'three3'] ],
},
);

my $test_count = 0;
foreach my $eg (@equiv_groups) {
    $test_count += scalar keys %$eg;
}

plan tests => 2 * $test_count;

Test::Group->verbose(2);

foreach my $eg (@equiv_groups) {
    my $want_labels = $eg->{'p'} || $eg->{'pp'} || $eg->{'ppp'};
    my @want_diag = ('Running group of tests - foo outer');
    my $subtest_num = 1;
    foreach my $label (@$want_labels) {
        push @want_diag, "ok 1.$subtest_num foo inner (foo=$label)";
        ++$subtest_num;
    }

    while ( my ($name, $vals) = each %$eg ) {
        my $vals_copy = clone($vals);
        next_test_foreach my $foo, 'foo', @$vals;
        is_deeply $vals, $vals_copy, "vals array not modified";

        test_out("ok 1 - foo outer");
        test_diag(@want_diag);
        test 'foo outer' => sub { ok 1, 'foo inner' };
        test_test("label pattern $name"); 
    }
} 

sub clone {
    my $thing = shift;

    ref $thing or return $thing;
    if (ref $thing eq 'ARRAY') {
        return [ map {clone($_)} @$thing ];
    } else {
        die "can't clone a ".ref($thing);
    }
}

