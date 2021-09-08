use strict;
use warnings;
use utf8;
use open IO => ':utf8', ':std';
use lib 't/lib'; use Text::VPrintf;

use Test::More;

sub bs {
    $_[0] =~ s/(\S)/$1\b$1/gr;
}

is( Text::VPrintf::sprintf( "%12s",    bs("abcde")),  bs("       abcde"), 'ASCII %s' );

is( Text::VPrintf::sprintf( "%12s",    bs("あいうえお")), bs("  あいうえお"),  'wide %s' );
is( Text::VPrintf::sprintf( "%12s",   bs("aあいうえお")), bs(" aあいうえお"),  'wide %s' );
is( Text::VPrintf::sprintf( "%12s",  bs("aaあいうえお")), bs("aaあいうえお"),  'wide %s' );
is( Text::VPrintf::sprintf( "%12s", bs("aaaあいうえお")), bs("aaaあいうえお"), 'wide %s' );

is( Text::VPrintf::sprintf("%-12s",    bs("あいうえお")), bs("あいうえお  ") , 'wide %-s' );
is( Text::VPrintf::sprintf("%-12s",   bs("aあいうえお")), bs("aあいうえお ") , 'wide %-s' );
is( Text::VPrintf::sprintf("%-12s",  bs("aaあいうえお")), bs("aaあいうえお") , 'wide %-s' );
is( Text::VPrintf::sprintf("%-12s", bs("aaaあいうえお")), bs("aaaあいうえお"), 'wide %-s' );

is( Text::VPrintf::sprintf( "%7s",    bs("ｱｲｳｴｵ")),  bs("  ｱｲｳｴｵ"), 'half %s' );
is( Text::VPrintf::sprintf( "%7s",   bs("aｱｲｳｴｵ")),  bs(" aｱｲｳｴｵ"), 'half %s' );
is( Text::VPrintf::sprintf( "%7s",  bs("aaｱｲｳｴｵ")),  bs("aaｱｲｳｴｵ"), 'half %s' );
is( Text::VPrintf::sprintf( "%7s", bs("aaaｱｲｳｴｵ")), bs("aaaｱｲｳｴｵ"), 'half %s' );

is( Text::VPrintf::sprintf("%-7s",    bs("ｱｲｳｴｵ")), bs("ｱｲｳｴｵ  ") , 'half %-s' );
is( Text::VPrintf::sprintf("%-7s",   bs("aｱｲｳｴｵ")), bs("aｱｲｳｴｵ ") , 'half %-s' );
is( Text::VPrintf::sprintf("%-7s",  bs("aaｱｲｳｴｵ")), bs("aaｱｲｳｴｵ") , 'half %-s' );
is( Text::VPrintf::sprintf("%-7s", bs("aaaｱｲｳｴｵ")), bs("aaaｱｲｳｴｵ"), 'half %-s' );

done_testing;
