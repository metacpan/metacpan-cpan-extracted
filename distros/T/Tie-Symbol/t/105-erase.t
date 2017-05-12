#!perl

use strict;
use warnings FATAL => 'all';
use Test::Most qw(!code);
use Tie::Symbol;

#plan tests => 15;

tie( my %ST, 'Tie::Symbol' );

sub code { 123 }
our $scalar = 456;
our @array  = qw(7 8 9);
our %hash   = ( 10, 11, 12, 13 );

my $scalarref = delete $ST{'$scalar'};
my $arrayref  = delete $ST{'@array'};
my $hashref   = delete $ST{'%hash'};
my $coderef   = delete $ST{'&code'};

throws_ok {
    &code or die;
}
qr{Undefined subroutine &main::code called}, '&code deleted';

throws_ok {
    $scalar or die;
}
qr{Died}, '$scalar deleted';

throws_ok {
    @array or die;
}
qr{Died}, '@array deleted';

throws_ok {
    %hash or die;
}
qr{Died}, '%hash deleted';

is $coderef->() => 123, '&coderef survived';
is_deeply $scalarref => \456, '$scalar survived';
is_deeply $arrayref => [ 7, 8, 9 ], '@array survived';
is_deeply $hashref => { 10, 11, 12, 13 }, '%hash survived';

done_testing;
