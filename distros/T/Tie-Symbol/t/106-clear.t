#!perl

package abc;

our @array;
our %hash;
sub code;

package abc::def;

our @array;
our %hash;
sub code;

package main;

use strict;
use warnings FATAL => 'all';
use Test::Most qw(!code);
use Tie::Symbol;

#plan tests => 6;

tie( my %ST, 'Tie::Symbol', 'abc' );

%ST = ();

throws_ok {
    &abc::code or die;
}
qr{Undefined subroutine &abc::code called}, '&abc::code deleted';

throws_ok {
    @abc::array or die;
}
qr{Died}, '@abc::array deleted';

throws_ok {
    %abc::hash or die;
}
qr{Died}, '%abc::hash deleted';

throws_ok {
    &abc::def::code or die;
}
qr{Undefined subroutine &abc::def::code called}, '&abc::def::code deleted';

throws_ok {
    @abc::def::array or die;
}
qr{Died}, '@abc::def::array deleted';

throws_ok {
    %abc::def::hash or die;
}
qr{Died}, '%abc::def::hash deleted';

done_testing;
