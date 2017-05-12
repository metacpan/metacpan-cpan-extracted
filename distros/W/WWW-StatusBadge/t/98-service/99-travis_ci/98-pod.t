#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use Scalar::Util ();

require 't/common.pl';

# BEGIN: 1 render default render
is(
    common_object()->pod,
    sprintf(
        '=for %s <a href="%s"><img src="%s" alt="%s" /></a>',
        'html',
        common_url(),
        common_img(),
        common_txt(),
    ),
    'render default render'
);

# BEGIN: 1 render valid render
is(
    common_object()->pod('markdown'),
    sprintf(
        '=for %s %s',
        'markdown',
        common_object()->markdown
    ),
    'render valid render'
);

# BEGIN: 1 render invalid render
eval { common_object()->pod('invalid'), };
like(
    $@,
    qr/^Can't locate object method "invalid"/,
    'render invalid render'
);
