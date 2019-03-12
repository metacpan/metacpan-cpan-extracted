#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use X::Tiny;
use X::Tiny::Base;

print "1..1$/";

my $label = 'overload.pm is not loaded by default';

if (overload->can(q<StrVal>)) {
    print "not ";
}

print "ok 1 - $label$/";
