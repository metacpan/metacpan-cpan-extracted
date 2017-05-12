use 5.008001;
use Test::Roo; # should import Moo as well

use lib 't/lib';

has fixture => (
    is      => 'ro',
    default => sub { "hello world" },
);

with qw/RoleNotFoundAnywhere/;

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
