#!/usr/bin/env perl

use strict;
use warnings;

use Test::Validator::Declarative qw/ check_type_validation /;

check_type_validation(
    type => 'bool',
    good => [
        ## all FALSEs
        '',  'F',     'FALSE', 'N', 'NO',
        'f', 'false', 'n',     'no',
        0,
        ## all TRUEs
        'T', 'TRUE', 'Y', 'YES',
        't', 'true', 'y', 'yes',
        1
    ],
    bad => [
        'some string',    # arbitrary string
        10,               # arbitrary number
        'NOT',            # mistype
        sub { return 'TRUE' },    # coderef
    ],
);

