#!/usr/bin/env perl

use strict;
use warnings;

use Test::Validator::Declarative qw/ check_converter_validation /;

check_converter_validation(
    type   => 'assume_true',
    result => {
        1 => [
            ## all TRUEs
            'T', 'TRUE', 'Y', 'YES',
            't', 'true', 'y', 'yes',
            1,
            '',               # empty string
            'some string',    # arbitrary string
            10,               # arbitrary number
            'NOT',            # mistype
            sub { return 'TRUE' },    # coderef
        ],
        0 => [
            ## all FALSEs
            'F', 'FALSE', 'N', 'NO',
            'f', 'false', 'n', 'no',
            0,
        ],
    },
);

