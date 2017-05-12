#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use 5.010000;
use autodie;

use Test::More;
use Test::Ika;

describe 'foo' => sub {
    before_each {
        warn "OUTER BEFORE";
    };
    after_each {
        warn "OUTER AFTER";
    };
    describe 'x' => sub {
        before_each {
            warn "BEFORE_INNER";
        };
        after_each {
            warn "AFTER_INNER";
        };
        it y => sub {
            ok 1;
        };
        it z => sub {
            ok 1;
        };
    };
};
