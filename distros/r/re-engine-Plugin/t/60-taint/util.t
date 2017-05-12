#!/usr/bin/env perl -T
use strict;
use Test::More;

BEGIN {
    eval {
        require Taint::Util;
        Taint::Util->import;
    };

    plan $@
        ? (skip_all => "Taint::Util required for taint tests")
        : (tests => 8);
}

use re::engine::Plugin (
    exec => sub {
        my ($re, $str) = @_;

        ok(tainted($str) => 'matched string tainted');

        my $one = $str;
        my $two = $str; untaint($two);

        ok(tainted($one));
        ok(!tainted($two));

        $re->num_captures(
            FETCH => sub {
                my ($re, $p) = @_;

                return $one if $p == 1;
                return $two if $p == 2;
            },
        );

        1;
    }
);

my $str = "string";
taint($str);
ok(tainted($str));

if ($str =~ /pattern/) {
    cmp_ok $1, 'eq', $str;
    ok(tainted($1) => '$1 is tainted');

    cmp_ok $2, 'eq', $str;
    ok(!tainted($2) => '$2 is untainted');
}
