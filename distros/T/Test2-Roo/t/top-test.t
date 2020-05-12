use 5.008001;
use Test2::Roo;

has fixture => (
    is      => 'ro',
    default => sub { "hello world" },
);

top_test try_me => sub {
    my $self = shift;
    like( $self->fixture, qr/hello world/, "saw fixture" );
};

run_me;
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
