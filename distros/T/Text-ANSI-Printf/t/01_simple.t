use v5.14;
use warnings;
use utf8;
use open IO => ':utf8', ':std';
use Text::ANSI::Printf;

sub r {
    local $_ = shift;
    s/(\S+)/\e[31m$1\e[m/r;
}

use Test::More;

is( Text::ANSI::Printf::sprintf( "%d %5.3f", 12345, 12.345),
    "12345 12.345",
    'Number %d %f' );


is( Text::ANSI::Printf::sprintf( "%12s",            ""),  r("            "), 'ASCII %s (0-column)' );
is( Text::ANSI::Printf::sprintf( "%12s",        r("a")),  r("           a"), 'ASCII %s (1-column)' );
is( Text::ANSI::Printf::sprintf( "%12s",    r("abcde")),  r("       abcde"), 'ASCII %s' );


is( Text::ANSI::Printf::sprintf( "%12s",    r("あいうえお")),  r("  あいうえお"), 'wide %s' );
is( Text::ANSI::Printf::sprintf( "%12s",   r("aあいうえお")),  r(" aあいうえお"), 'wide %s' );
is( Text::ANSI::Printf::sprintf( "%12s",  r("aaあいうえお")),  r("aaあいうえお"), 'wide %s' );
is( Text::ANSI::Printf::sprintf( "%12s", r("aaaあいうえお")), r("aaaあいうえお"), 'wide %s' );

is( Text::ANSI::Printf::sprintf("%-12s",    r("あいうえお")), r("あいうえお  ") , 'wide %-s' );
is( Text::ANSI::Printf::sprintf("%-12s",   r("aあいうえお")), r("aあいうえお ") , 'wide %-s' );
is( Text::ANSI::Printf::sprintf("%-12s",  r("aaあいうえお")), r("aaあいうえお") , 'wide %-s' );
is( Text::ANSI::Printf::sprintf("%-12s", r("aaaあいうえお")), r("aaaあいうえお"), 'wide %-s' );

is( Text::ANSI::Printf::sprintf( "%7s",   r( "ｱｲｳｴｵ")),  r("  ｱｲｳｴｵ"), 'half %s' );
is( Text::ANSI::Printf::sprintf( "%7s",   r("aｱｲｳｴｵ")),  r(" aｱｲｳｴｵ"), 'half %s' );
is( Text::ANSI::Printf::sprintf( "%7s",  r("aaｱｲｳｴｵ")),  r("aaｱｲｳｴｵ"), 'half %s' );
is( Text::ANSI::Printf::sprintf( "%7s", r("aaaｱｲｳｴｵ")), r("aaaｱｲｳｴｵ"), 'half %s' );

is( Text::ANSI::Printf::sprintf("%-7s",    r("ｱｲｳｴｵ")), r("ｱｲｳｴｵ  ") , 'half %-s' );
is( Text::ANSI::Printf::sprintf("%-7s",   r("aｱｲｳｴｵ")), r("aｱｲｳｴｵ ") , 'half %-s' );
is( Text::ANSI::Printf::sprintf("%-7s",  r("aaｱｲｳｴｵ")), r("aaｱｲｳｴｵ") , 'half %-s' );
is( Text::ANSI::Printf::sprintf("%-7s", r("aaaｱｲｳｴｵ")), r("aaaｱｲｳｴｵ"), 'half %-s' );

done_testing;
