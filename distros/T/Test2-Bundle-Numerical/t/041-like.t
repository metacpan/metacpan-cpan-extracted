use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan(2);

like('abc123', qr/^abc/, 'like matches prefix');
like('123abc', qr/abc$/, 'like matches suffix');
