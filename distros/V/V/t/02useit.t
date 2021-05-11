#! perl -I. -w
use t::Test::abeltje;

$|=1;

package Catch;
sub TIEHANDLE { bless \( my $self ), shift }
sub PRINT  { my $self = shift; $$self .= $_[0] }
sub PRINTF {
    my $self = shift;
    my $format = shift;
    $$self .= sprintf $format, @_;
}

package main;
require_ok( 'V' );

local *CATCHOUT;
my $out = tie *CATCHOUT, 'Catch';
my $stdout = select CATCHOUT;

$V::NO_EXIT = 1;
V->import( 'V' );
select $stdout;

ok( $$out, "V->import() produced output" );
like( $$out, qr/^V\n/, "Module is V" );
like( $$out, qr/^\t(.+?)V\.pm: $V::VERSION$/m, "VERSION is $V::VERSION" );
is( $V::NO_EXIT, 1 , "Packagevar \$V::NO_EXIT set" );

is( V::get_version( 'V' ), $V::VERSION, "get_version()" );

abeltje_done_testing();
