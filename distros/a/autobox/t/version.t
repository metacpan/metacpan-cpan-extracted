#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 14;
use FindBin qw($Bin);
use lib "$Bin/lib";

use Versioned;

{
    use autobox UNIVERSAL => 'Versioned';
    my $want = '0.42';

    is 42->autobox_class->test, $want;
    is 42->autobox_class->VERSION, $want;
    is 3.1415927->autobox_class->test, $want;
    is 3.1415927->autobox_class->VERSION, $want;
    is ''->autobox_class->test, $want;
    is ''->autobox_class->VERSION, $want;
    is 'Hello, world!'->autobox_class->test, $want;
    is 'Hello, world!'->autobox_class->VERSION, $want;
    is []->autobox_class->test, $want;
    is []->autobox_class->VERSION, $want;
    is {}->autobox_class->test, $want;
    is {}->autobox_class->VERSION, $want;
    is sub {}->autobox_class->test, $want;
    is sub {}->autobox_class->VERSION, $want;
}
