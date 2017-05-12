#!/usr/bin/perl
# vim: set ft=perl:
# Stolen from Andy Lester, from 
# <http://use.perl.org/~petdance/journal/12391>

use Test::More;
use File::Spec;
use strict;

eval "use Test::Pod 0.95";

if ($@) {
    plan skip_all => "Test::Pod v0.95 required for testing POD";
} else {
    plan tests => 1;
    Test::Pod::pod_file_ok(File::Spec->catfile(qw(blib script urifind)));
}
