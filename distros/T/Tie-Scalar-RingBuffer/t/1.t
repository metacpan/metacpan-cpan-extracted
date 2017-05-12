use Test::More tests => 9;
use strict;
use warnings;
BEGIN { use_ok('Tie::Scalar::RingBuffer') };

my @data = qw(a b c);
my ($x,$s);

## Simple list
tie $x, 'Tie::Scalar::RingBuffer', \@data;
$s = '';
for (1..10){
    $s .= $x;
}
ok($s eq 'abcabcabca');
untie $x;

## empty options
tie $x, 'Tie::Scalar::RingBuffer', \@data, +{};
$s = '';
for (1..10){
    $s .= $x;
}
ok($s eq 'abcabcabca');
untie $x;

## increment by two
tie $x, 'Tie::Scalar::RingBuffer', \@data, { increment => 2};
$s = '';
for (1..10){
    $s .= $x;
}
ok($s eq 'acbacbacba');
untie $x;

## start at 2
tie $x, 'Tie::Scalar::RingBuffer', \@data, { start_offset => 2 };
$s = '';
for (1..10){
    $s .= $x;
}
ok($s eq 'cabcabcabc');
untie $x;

## negative start_offset
tie $x, 'Tie::Scalar::RingBuffer', \@data, { start_offset => -1 };
$s = '';
for (1..10){
    $s .= $x;
}
ok($s eq 'cabcabcabc');
untie $x;

## negative increment
tie $x, 'Tie::Scalar::RingBuffer', \@data, { increment => -1 };
$s = '';
for (1..10){
    $s .= $x;
}
ok($s eq 'acbacbacba');
untie $x;


## random
srand(0);
tie $x, 'Tie::Scalar::RingBuffer', \@data, { random => 1 };
$s = '';
for (1..10){
    $s .= $x;
}
srand(0);
ok($s eq join '', map {$data[rand scalar @data]} (1..10));
untie $x;

## STORE
tie $x, 'Tie::Scalar::RingBuffer', \@data;
$s = '';
for (0..$#data){ $x = uc $x }
for (1..10){
    $s .= $x;
}
ok($s eq 'ABCABCABCA');



#### OO syntax
##$x = new Tie::Scalar::RingBuffer(\@data);
##$s = '';
##for (1..10){
##    $s .= $x;
##}
##ok($s eq 'abcabcabca');

__END__
# vim:set ft=perl ai si et ts=4 sts=4 sw=4 tw=0:
