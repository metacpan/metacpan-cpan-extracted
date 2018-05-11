use 5.014;
no if $] >= 5.018, warnings => "experimental::smartmatch";
use strict;
use Test::More tests => 24;

use Var::Pairs;

my %data1 = ( 1 => 'a', 2 => 'b' );
my %data2 = ( 1 => 'aa', 2 => 'bb' );

my $next_ref = \%data1;

while (my ($key, $value) = each_kv $next_ref) {
    ok exists $next_ref->{$key}   => 'Valid key returned';
    is $next_ref->{$key}, $value => 'Correct value returned';

    $next_ref = $next_ref == \%data1 ? \%data2 : \%data1;
}


$next_ref = \%data1;

my $next_expected = 0;
while (my $pair = each_pair $next_ref) {
    ok exists $next_ref->{$pair->key}        => 'Valid key returned';
    is $next_ref->{$pair->key}, $pair->value => 'Correct value returned';

    $next_ref = $next_ref == \%data1 ? \%data2 : \%data1;
}



for my $next_ref (\%data1, \%data2) {
    for my $pair (pairs %{$next_ref}) {
        ok exists $next_ref->{$pair->key}        => 'Valid key returned';
        is $next_ref->{$pair->key}, $pair->value => 'Correct value returned';
    }
}




