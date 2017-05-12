use 5.008001;
use Test::Roo import => [qw/like done_testing/];

has fixture => (
    is      => 'ro',
    default => sub { "hello world" },
);

test try_me => sub {
    my $self = shift;
    like( $self->fixture, qr/hello world/, "saw fixture" );
    eval { fail("fail() called") };
    like( $@, qr/undefined subroutine/i, "Not all Test::More functions imported" );
};

run_me;
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
