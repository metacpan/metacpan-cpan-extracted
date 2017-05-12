#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 1;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use UR;

$ENV{UR_STACK_DUMP_ON_DIE}=1;

sub a { b(@_) }
sub b { c(@_) }
sub c { d(@_) } 
sub d { die 'expected' }

eval { 
    &a
};

if ($@) {
    note $@;
    if ($@ =~ /main::b\(\) called/g) {
        fail('got a stack trace in eval');
    } else {
        pass('looks good');
    }
} else {
    fail('$@ wasnt set');
}

#&a;

