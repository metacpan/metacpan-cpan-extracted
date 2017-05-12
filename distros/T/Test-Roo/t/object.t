use 5.008001;

package MyTest;
use Test::Roo;

has fixture => (
    is      => 'ro',
    default => sub { "hello world" },
);

test try_me => sub {
    my $self = shift;
    like( $self->fixture, qr/hello world/, "saw fixture" );
};

package main;
use strictures;
use Test::More;

my $obj = MyTest->new;
$obj->run_tests;
$obj->run_tests("with description");

done_testing;
#
# This file is part of Test-Roo
#
# This software is Copyright (c) 2013 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
# vim: ts=4 sts=4 sw=4 et:
