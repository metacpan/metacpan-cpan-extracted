package strict;
no thanks;
package main;
use Test::More tests => 1;
use strict;

ok not(strict->can('unimport'));
