#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use lib 't/lib';

BEGIN { use_ok 'multidimensional' }

my %a;

foreach (
    ['no multidimensional;', '$a{1,2} if 0'],
    ['no multidimensional;', '{ $a{1,2} if 0 }'],
    ['no multidimensional; { use multidimensional; }', '$a{1,2} if 0'],
) {
    my ($prep, $test) = @{$_};
    my $code = $prep.$test;
    eval $code;
    like $@, qr/Use of multidimensional array emulation/, $code;
    SKIP: {
        skip "lexical hints don't propagate into eval on this perl", 7
            unless "$]" >= 5.009003;
        $code = $prep." eval(q{$test}); die \$@ if \$@";
        eval $code;
        like $@, qr/Use of multidimensional array emulation/, $code;
    }
}

foreach my $code (
    'no multidimensional; { use multidimensional; $a{1,2} if 0 }',
    'no multidimensional; use multidimensional; $a{1,2} if 0',
    '{ no multidimensional; } $a{1,2} if 0',
    'no multidimensional; require MyTest',
    'no multidimensional; $a{join(my $sep = $;, 1, 2)} if 0',
    'no multidimensional; my $sep = $;; $a{join($sep, 1, 2)} if 0',
    'no multidimensional; $a{join($;, 1, 2)} if 0',
) {
    eval $code;
    is $@, "", $code;
}

done_testing;
