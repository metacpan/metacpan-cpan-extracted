use 5.008001;
use Test2::Roo;

$foo = "1.23";

test 'just pass' => sub { ok(1) };

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
