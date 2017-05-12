#!perl -T

use strict;
use warnings;

use Test::More tests => 8;

use with \bless {}, 'with::Mock';

sub shift { }
sub with::Mock::pop { }
sub durrr () { 79 }
sub dongs () { 53 }
sub with::Mock::dongs { CORE::shift; $_[0] + $_[1] }
sub hlagh { 2 * $_[0] + $_[1] }
sub with::Mock::boner { CORE::shift; $_[0] + 2 * $_[1] }

my @a;
@a = 1;
push @a, 2;         # with::corewrap, defaulting to CORE
is $a[1], 2, 'CORE::push';
shift @a;           # with::corewrap, function in caller namespace
is $a[1], 2, 'main::shift';
pop @a;             # with::corewrap, method call
is $a[1], 2, 'with::Mock::pop';
my $x = durrr @a;   # with::subwrap, function in caller namespace
is $x, 79, 'main::durrr';
my $y = dongs @a;   # with::subwrap, method call
is $y, 3, 'with::Mock::dongs';
my $z = hlagh @a;   # with::defer, function in caller namespace
is $z, 4, 'main::hlagh';
my $t = boner @a;   # with::defer, method call
is $t, 5, 'with::Mock::boner';
eval { zogzog @a }; # with::defer, no such fonction
like $@, qr/Undefined\s+subroutine/, 'no zogzog';

