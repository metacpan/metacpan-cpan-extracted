#!/usr/bin/env perl
use strict;
use warnings;

use UNIVERSAL::to_yaml;
use Test::More;

plan( tests => 1 );

my $foo = bless { This => "this value", That => 'That Value' }, "Foo";

like( $foo->to_yaml , qr{perl/hash:Foo});

