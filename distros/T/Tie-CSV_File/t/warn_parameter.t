#!/usr/bin/perl

use strict;
use warnings;

use Tie::CSV_File;
use Test::Warn;
use Data::Dumper;

use constant WARNING_PARAMETERS => (
    [[sep_char => undef], qr/sep_char/i],
    [[sep_char => ''],    qr/sep_char/i],
    [[sep_char => '  '],  qr/sep_char/i],
    [[sep_char => ' ', sep_re => qr/\S/],   qr/sep_char/i]
);

use Test::More tests => scalar WARNING_PARAMETERS;

foreach (WARNING_PARAMETERS) {
    my ($parameters, $warning_re) = @$_;
    warning_like {tie my @data,  'Tie::CSV_File', 'foo.csv', @$parameters}
                 {carped => $warning_re}
    or diag("warning params=" . Dumper($_));
}

unlink 'foo.csv';

1;
