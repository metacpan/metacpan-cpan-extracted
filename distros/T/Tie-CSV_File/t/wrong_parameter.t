#!/usr/bin/perl 

use strict;
use warnings;

use Tie::CSV_File;
use Test::Exception;

use constant WRONG_PARAMETERS => (
    ['/foo/bar/nonsens/nonsens.csv'],
    ['foo.dat', 'unknown option' => 3],
    ['foo.dat', 'eol'    => ['an arrayref']],
    ['foo.dat', 'sep_re' => "no regexp"],
);

use Test::More tests => scalar(WRONG_PARAMETERS);

foreach (WRONG_PARAMETERS) {
    dies_ok { tie my @data, 'Tie::CSV_File', @$_ }
            "should die with parameters " . join(",", @$_);
}
