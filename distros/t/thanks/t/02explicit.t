no thanks 'strict';
use Test::More tests => 1;
use strict;

ok not(strict->can('unimport'));
