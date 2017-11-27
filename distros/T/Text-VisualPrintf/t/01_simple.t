use strict;
use warnings;
use utf8;
use open ':std', ':encoding(utf8)';
use Text::VisualPrintf;

use Test::More tests => 16;

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
