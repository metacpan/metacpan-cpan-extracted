use strict;
use warnings;
use utf8;
use open IO => ':utf8', ':std';
use Text::VisualPrintf;

use Test::More;

is( Text::VisualPrintf::sprintf( "%d %5.3f", 12345, 12.345),
    "12345 12.345",
    'Number %d %f' );


is( Text::VisualPrintf::sprintf( "%12s",    "abcde"),  "       abcde", 'ASCII %s' );


is( Text::VisualPrintf::sprintf( "%12s",    "あいうえお"),  "  あいうえお", 'wide %s' );
is( Text::VisualPrintf::sprintf( "%12s",   "aあいうえお"),  " aあいうえお", 'wide %s' );
is( Text::VisualPrintf::sprintf( "%12s",  "aaあいうえお"),  "aaあいうえお", 'wide %s' );
is( Text::VisualPrintf::sprintf( "%12s", "aaaあいうえお"), "aaaあいうえお", 'wide %s' );

is( Text::VisualPrintf::sprintf("%-12s",    "あいうえお"), "あいうえお  " , 'wide %-s' );
is( Text::VisualPrintf::sprintf("%-12s",   "aあいうえお"), "aあいうえお " , 'wide %-s' );
is( Text::VisualPrintf::sprintf("%-12s",  "aaあいうえお"), "aaあいうえお" , 'wide %-s' );
is( Text::VisualPrintf::sprintf("%-12s", "aaaあいうえお"), "aaaあいうえお", 'wide %-s' );

is( Text::VisualPrintf::sprintf( "%7s",    "ｱｲｳｴｵ"),  "  ｱｲｳｴｵ", 'half %s' );
is( Text::VisualPrintf::sprintf( "%7s",   "aｱｲｳｴｵ"),  " aｱｲｳｴｵ", 'half %s' );
is( Text::VisualPrintf::sprintf( "%7s",  "aaｱｲｳｴｵ"),  "aaｱｲｳｴｵ", 'half %s' );
is( Text::VisualPrintf::sprintf( "%7s", "aaaｱｲｳｴｵ"), "aaaｱｲｳｴｵ", 'half %s' );

is( Text::VisualPrintf::sprintf("%-7s",    "ｱｲｳｴｵ"), "ｱｲｳｴｵ  " , 'half %-s' );
is( Text::VisualPrintf::sprintf("%-7s",   "aｱｲｳｴｵ"), "aｱｲｳｴｵ " , 'half %-s' );
is( Text::VisualPrintf::sprintf("%-7s",  "aaｱｲｳｴｵ"), "aaｱｲｳｴｵ" , 'half %-s' );
is( Text::VisualPrintf::sprintf("%-7s", "aaaｱｲｳｴｵ"), "aaaｱｲｳｴｵ", 'half %-s' );

done_testing;
