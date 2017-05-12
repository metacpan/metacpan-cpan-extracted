use strict;
use warnings;

use Test::More;
use Test::Warnings ':all';

eval 'use Foo::Bar::Baz';
plan skip_all => 'Need Foo::Bar::Baz to continue!' if $@;

fail('we should not ever get here');

