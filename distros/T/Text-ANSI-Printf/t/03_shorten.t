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

is( Text::ANSI::Printf::sprintf( "%.5s", r("abcde")),  r("abcde"), 'ASCII %.5s' );
is( Text::ANSI::Printf::sprintf( "%.4s", r("abcde")),  r("abcd"),  'ASCII %.4s' );
is( Text::ANSI::Printf::sprintf( "%.3s", r("abcde")),  r("abc"),   'ASCII %.3s' );
is( Text::ANSI::Printf::sprintf( "%.2s", r("abcde")),  r("ab"),    'ASCII %.2s' );
is( Text::ANSI::Printf::sprintf( "%.1s", r("abcde")),  r("a"),     'ASCII %.1s' );
is( Text::ANSI::Printf::sprintf( "%.0s", r("abcde")),  "",         'ASCII %.0s' );

is( Text::ANSI::Printf::sprintf( "%.10s", r("あいうえお")), r("あいうえお"), 'wide %.10s' );
is( Text::ANSI::Printf::sprintf( "%.9s" , r("あいうえお")), r("あいうえ "),  'wide %.9s' );
is( Text::ANSI::Printf::sprintf( "%.8s" , r("あいうえお")), r("あいうえ"),   'wide %.8s' );
is( Text::ANSI::Printf::sprintf( "%.7s" , r("あいうえお")), r("あいう "),    'wide %.7s' );
is( Text::ANSI::Printf::sprintf( "%.2s" , r("あいうえお")), r("あ"),         'wide %.2s' );
is( Text::ANSI::Printf::sprintf( "%.1s" , r("あいうえお")), r(" "),          'wide %.1s' );
is( Text::ANSI::Printf::sprintf( "%.0s" , r("あいうえお")), "",              'wide %.0s' );

is( Text::ANSI::Printf::sprintf( "%-.10s", r("あいうえお")), r("あいうえお"), 'wide %-.10s' );
is( Text::ANSI::Printf::sprintf( "%-.9s" , r("あいうえお")), r("あいうえ "),  'wide %-.9s' );
is( Text::ANSI::Printf::sprintf( "%-.8s" , r("あいうえお")), r("あいうえ"),   'wide %-.8s' );
is( Text::ANSI::Printf::sprintf( "%-.7s" , r("あいうえお")), r("あいう "),    'wide %-.7s' );

is( Text::ANSI::Printf::sprintf( "%.5s", r("ｱｲｳｴｵ")), r("ｱｲｳｴｵ"), 'half %.5s' );
is( Text::ANSI::Printf::sprintf( "%.4s", r("ｱｲｳｴｵ")), r("ｱｲｳｴ"),  'half %.4s' );
is( Text::ANSI::Printf::sprintf( "%.3s", r("ｱｲｳｴｵ")), r("ｱｲｳ"),   'half %.3s' );
is( Text::ANSI::Printf::sprintf( "%.2s", r("ｱｲｳｴｵ")), r("ｱｲ"),    'half %.2s' );
is( Text::ANSI::Printf::sprintf( "%.1s", r("ｱｲｳｴｵ")), r("ｱ"),     'half %.1s' );
is( Text::ANSI::Printf::sprintf( "%.0s", r("ｱｲｳｴｵ")), "",         'half %.0s' );

done_testing;
