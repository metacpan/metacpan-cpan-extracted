#!/usr/bin/env perl

# Thanks to Schwern for this test case:
# https://rt.cpan.org/Ticket/Display.html?id=55652

use strict;
use warnings;

use autobox;

use Test::More tests => 4;

sub SCALAR::method {
    pass("method called $_[1]");
    bless \$_[0], 'Meta';
}

my $native = 42;

$native->method('once');
is($native, 42, '$native == 42 after first method call');

$native->method('twice');
is($native, 42, '$native == 42 after second method call');
