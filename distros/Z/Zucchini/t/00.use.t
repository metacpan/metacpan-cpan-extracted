#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
    use_ok 'Zucchini';
    use_ok 'Zucchini::Config';
    use_ok 'Zucchini::Config::Create';
}
