#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

{
    use_ok('Wrap::Sub');
    my $wrap = Wrap::Sub->new;

    eval { my $caller = $wrap->wrap('caller'); };

    like ($@,  qr/can't wrap/, "core functions can't be wrapped");
};

done_testing();
