#!perl -T

use strict;
use warnings;

use Test::More tests => 2;

use Variable::Magic qw<MGf_COPY MGf_DUP>;

ok MGf_COPY, 'MGf_COPY is always true';
ok MGf_DUP,  'MGf_DUP is always true';
