use 5.008001;

package MyTest;
use Test2::Roo;

use lib 't/lib';

has class => (
    is       => 'ro',
    required => 1,
);

with 'ClassConstructor';

package main;
use strictures;
use Test2::V0;

for my $c (qw/Digest::MD5 Math::BigInt/) {
    MyTest->run_tests( $c, { class => $c } );
}

done_testing;
#
# This file is part of Test2-Roo
#
# This software is Copyright (c) 2020 by David Golden, Diab Jerius (Smithsonian Astrophysical Observatory).
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
# vim: ts=4 sts=4 sw=4 et:
