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

$ST{'&code'}   = sub { 1230 };
$ST{'$scalar'} = \4560;
$ST{'@array'}  = [ 7, 8, 9, 0 ];
$ST{'%hash'}   = { 100, 110, 120, 130 };

is code()  => 1230, '&code changed';
is $scalar => 4560, '$scalar changed';
is_deeply \@array => [ 7,   8,   9,   0 ],   '@array changed';
is_deeply \%hash  => { 100, 110, 120, 130 }, '%hash changed';

throws_ok {
    $ST{'$abc'} = 0;
}
qr{cannot assign unreferenced thing to \$abc}, '$abc = 0';

throws_ok {
    $ST{'@abc'} = 0;
}
qr{cannot assign unreferenced thing to \@abc}, '@abc = 0';

throws_ok {
    $ST{'%abc'} = 0;
}
qr{cannot assign unreferenced thing to \%abc}, '%abc = 0';

throws_ok {
    $ST{'&abc'} = 0;
}
qr{cannot assign unreferenced thing to \&abc}, '&abc = 0';

my $bad = bless(
    do { \( my $o = 0 ) }
      => 'bad'
);

throws_ok {
    $ST{'$abc'} = $bad;
}
qr{\Qcannot assign $bad to SCALAR\E}, "\$abc = $bad";

throws_ok {
    $ST{'@abc'} = $bad;
}
qr{\Qcannot assign $bad to ARRAY\E}, "\@abc = $bad";

throws_ok {
    $ST{'%abc'} = $bad;
}
qr{\Qcannot assign $bad to HASH\E}, "\%abc = $bad";

throws_ok {
    $ST{'&abc'} = $bad;
}
qr{\Qcannot assign $bad to CODE\E}, "\&abc = $bad";

throws_ok {
    &abc::def::code or die;
}
qr{Undefined subroutine &abc::def::code called},
  '&abc::def::code exists not yet';

throws_ok {
    $abc::def::scalar or die;
}
qr{Died}, '$abc::def::scalar exists not yet';

throws_ok {
    @abc::def::array or die;
}
qr{Died}, '@abc::def::array exists not yet';

throws_ok {
    %abc::def::hash or die;
}
qr{Died}, '%abc::def::hash exists not yet';

$ST{'&abc::def::code'}   = sub { 1 };
$ST{'$abc::def::scalar'} = \1;
$ST{'@abc::def::array'}  = [1];
$ST{'%abc::def::hash'}   = { 1, 1 };

ok &abc::def::code, '&abc::def::code ok';
ok $abc::def::scalar, '$abc::def::scalar ok';
ok @abc::def::array, '@abc::def::array ok';
ok %abc::def::hash,  '%abc::def::hash ok';

done_testing;
