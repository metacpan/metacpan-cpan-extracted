use strict;
use warnings;
use utf8;
use open IO => ':utf8', ':std';
use lib 't/lib'; use Text::VPrintf;

use Test::More;

is( Text::VPrintf::sprintf( "%d %5.3f", 12345, 12.345),
    "12345 12.345",
    'Number %d %f' );


is( Text::VPrintf::sprintf( "%12s",    "abcde"),  "       abcde", 'ASCII %s' );


is( Text::VPrintf::sprintf( "%12s",    "あいうえお"),  "  あいうえお", 'wide %s' );
is( Text::VPrintf::sprintf( "%12s",   "aあいうえお"),  " aあいうえお", 'wide %s' );
is( Text::VPrintf::sprintf( "%12s",  "aaあいうえお"),  "aaあいうえお", 'wide %s' );
is( Text::VPrintf::sprintf( "%12s", "aaaあいうえお"), "aaaあいうえお", 'wide %s' );

is( Text::VPrintf::sprintf("%-12s",    "あいうえお"), "あいうえお  " , 'wide %-s' );
is( Text::VPrintf::sprintf("%-12s",   "aあいうえお"), "aあいうえお " , 'wide %-s' );
is( Text::VPrintf::sprintf("%-12s",  "aaあいうえお"), "aaあいうえお" , 'wide %-s' );
is( Text::VPrintf::sprintf("%-12s", "aaaあいうえお"), "aaaあいうえお", 'wide %-s' );

is( Text::VPrintf::sprintf( "%7s",    "ｱｲｳｴｵ"),  "  ｱｲｳｴｵ", 'half %s' );
is( Text::VPrintf::sprintf( "%7s",   "aｱｲｳｴｵ"),  " aｱｲｳｴｵ", 'half %s' );
is( Text::VPrintf::sprintf( "%7s",  "aaｱｲｳｴｵ"),  "aaｱｲｳｴｵ", 'half %s' );
is( Text::VPrintf::sprintf( "%7s", "aaaｱｲｳｴｵ"), "aaaｱｲｳｴｵ", 'half %s' );

is( Text::VPrintf::sprintf("%-7s",    "ｱｲｳｴｵ"), "ｱｲｳｴｵ  " , 'half %-s' );
is( Text::VPrintf::sprintf("%-7s",   "aｱｲｳｴｵ"), "aｱｲｳｴｵ " , 'half %-s' );
is( Text::VPrintf::sprintf("%-7s",  "aaｱｲｳｴｵ"), "aaｱｲｳｴｵ" , 'half %-s' );
is( Text::VPrintf::sprintf("%-7s", "aaaｱｲｳｴｵ"), "aaaｱｲｳｴｵ", 'half %-s' );

done_testing;
