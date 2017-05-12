#!perl -T

use strict;
use warnings;

use Test::More tests => 4 + 1;
use Test::NoWarnings;
use Test::Differences;

BEGIN {
    use_ok('Test::HexDifferences::HexDump');
}

*next_format = \&Test::HexDifferences::HexDump::_next_format;

{
    my $data_pool = {
        format => "%4a : %1C : %d\n%*x",
    };
    next_format($data_pool);
    my $format_block = $data_pool->{format_block};
    next_format($data_pool);
    $format_block .= $data_pool->{format_block};
    eq_or_diff(
        $format_block,
        "%4a : %1C : %d\n"
        . "%4a : %1C : %d\n",
        'read format* 2 times',
    );
}

{
    my $data_pool = {
        format => "%a %2C\n%1x"
                  . "%a %5C %d\n%2x",
    };
    next_format($data_pool);
    my $format_block = $data_pool->{format_block};
    next_format($data_pool);
    $format_block .= $data_pool->{format_block};
    next_format($data_pool);
    $format_block .= $data_pool->{format_block};
    eq_or_diff(
        $format_block,
        "%a %2C\n"
        . "%a %5C %d\n"
        . "%a %5C %d\n",
        'read format + format',
    );
    next_format($data_pool);
    $format_block = $data_pool->{format_block};
    eq_or_diff(
        $format_block,
        "%a : %4C : %d\n",
        'read none existing format',
    );
}
