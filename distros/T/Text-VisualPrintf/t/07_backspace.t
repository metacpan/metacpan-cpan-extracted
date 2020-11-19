use strict;
use warnings;
use utf8;
use open IO => ':utf8', ':std';
use Text::VisualPrintf;

use Test::More;

sub bs {
    $_[0] =~ s/(\S)/$1\b$1/gr;
}

is( Text::VisualPrintf::sprintf( "%12s",    bs("abcde")),  bs("       abcde"), 'ASCII %s' );

is( Text::VisualPrintf::sprintf( "%12s",    bs("あいうえお")), bs("  あいうえお"),  'wide %s' );
is( Text::VisualPrintf::sprintf( "%12s",   bs("aあいうえお")), bs(" aあいうえお"),  'wide %s' );
is( Text::VisualPrintf::sprintf( "%12s",  bs("aaあいうえお")), bs("aaあいうえお"),  'wide %s' );
is( Text::VisualPrintf::sprintf( "%12s", bs("aaaあいうえお")), bs("aaaあいうえお"), 'wide %s' );

is( Text::VisualPrintf::sprintf("%-12s",    bs("あいうえお")), bs("あいうえお  ") , 'wide %-s' );
is( Text::VisualPrintf::sprintf("%-12s",   bs("aあいうえお")), bs("aあいうえお ") , 'wide %-s' );
is( Text::VisualPrintf::sprintf("%-12s",  bs("aaあいうえお")), bs("aaあいうえお") , 'wide %-s' );
is( Text::VisualPrintf::sprintf("%-12s", bs("aaaあいうえお")), bs("aaaあいうえお"), 'wide %-s' );

is( Text::VisualPrintf::sprintf( "%7s",    bs("ｱｲｳｴｵ")),  bs("  ｱｲｳｴｵ"), 'half %s' );
is( Text::VisualPrintf::sprintf( "%7s",   bs("aｱｲｳｴｵ")),  bs(" aｱｲｳｴｵ"), 'half %s' );
is( Text::VisualPrintf::sprintf( "%7s",  bs("aaｱｲｳｴｵ")),  bs("aaｱｲｳｴｵ"), 'half %s' );
is( Text::VisualPrintf::sprintf( "%7s", bs("aaaｱｲｳｴｵ")), bs("aaaｱｲｳｴｵ"), 'half %s' );

is( Text::VisualPrintf::sprintf("%-7s",    bs("ｱｲｳｴｵ")), bs("ｱｲｳｴｵ  ") , 'half %-s' );
is( Text::VisualPrintf::sprintf("%-7s",   bs("aｱｲｳｴｵ")), bs("aｱｲｳｴｵ ") , 'half %-s' );
is( Text::VisualPrintf::sprintf("%-7s",  bs("aaｱｲｳｴｵ")), bs("aaｱｲｳｴｵ") , 'half %-s' );
is( Text::VisualPrintf::sprintf("%-7s", bs("aaaｱｲｳｴｵ")), bs("aaaｱｲｳｴｵ"), 'half %-s' );

done_testing;
