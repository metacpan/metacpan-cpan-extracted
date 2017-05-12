#!perl

use 5.010001;
use strict;
use warnings;

use Test::Exception;
use Test::More 0.98;

use FindBin qw($Bin);
use lib "$Bin/t/lib", "$Bin/lib";

dies_ok  { eval "use Foo"     ; die $@ if $@ } 'use Foo needs version';
dies_ok  { eval "use Foo 0.0" ; die $@ if $@ } 'use Foo too old 0.0';
dies_ok  { eval "use Foo 0.01"; die $@ if $@ } 'use Foo too old 0.01';
dies_ok  { eval "use Foo 0.02"; die $@ if $@ } 'use Foo too old 0.02';
lives_ok { eval "use Foo 0.03"; die $@ if $@ } 'use Foo ok 0.03';
lives_ok { eval "use Foo 0.04"; die $@ if $@ } 'use Foo ok 0.04';
dies_ok  { eval "use Foo 0.05"; die $@ if $@ } 'use Foo too high 0.05';

lives_ok { eval "use Bar"     ; die $@ if $@ } 'use Bar ok no version';
lives_ok { eval "use Bar 0.0" ; die $@ if $@ } 'use Bar ok 0.0';
dies_ok  { eval "use Bar 0.01"; die $@ if $@ } 'use Bar too old 0.01';
dies_ok  { eval "use Bar 0.02"; die $@ if $@ } 'use Bar too old 0.02';
lives_ok { eval "use Bar 0.03"; die $@ if $@ } 'use Bar ok 0.03';
lives_ok { eval "use Bar 0.04"; die $@ if $@ } 'use Bar ok 0.04';
dies_ok  { eval "use Bar 0.05"; die $@ if $@ } 'use Bar too high 0.05';

DONE_TESTING:
done_testing;
