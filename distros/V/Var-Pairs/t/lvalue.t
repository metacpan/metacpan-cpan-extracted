use 5.014;
use strict;
use Test::More tests => 2;

use Var::Pairs;


my @data = 'a'..'f';
for my $next (pairs @data) {
    $next->value = uc $next->value;
}
is_deeply \@data, ['A'..'F']  => 'Lvalue array ->value';


my %data;
@data{1..6} = ('a'..'f');
for my $next (pairs %data) {
    $next->value .= 'z';
}
is_deeply [sort values %data], [qw(az bz cz dz ez fz)]  => 'Lvalue hash ->value';

