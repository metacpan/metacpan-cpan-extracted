#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;

BEGIN {
    use_ok('Text::SuDocs');
}

my @fail_strings = (
    'EP 1 998',
    'EP 1 998:',
    'EP 1.998/:',
    '1.998:',
    'EP 1998:',
    'EP 1.23: 998@',
    'EP 1.23: +998',
    'PR EX 28.8:C 76',
    'A 13.1/-2:P',
    'Y 3.P31:16/123',
    'Y 3.P 31 ASDF',
    'Y 3.P 31 1234',
    );
subtest 'These strings should fail' => sub {
    map { dies_ok {Text::SuDocs->new($_)} "Intentional fail on bad string '$_'" } @fail_strings;
    done_testing();
};
