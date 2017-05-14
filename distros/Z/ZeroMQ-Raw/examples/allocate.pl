#!/usr/bin/env perl

use strict;
use warnings;
use feature ':5.10';

use blib;

# not an example, but rather a script to allocate various resources
# so that we can see that they are deallocated in valgrind.
#
# oh and I know about Test::Valgrind.  i have found a coin flip to be
# a more accurate indicator of actual leaks.

use ZeroMQ::Raw;
use ZeroMQ::Raw::Constants qw(ZMQ_PUB ZMQ_SUB);

my $test = shift or die 'need test';
my $n    = shift or die 'need n';

my $c = ZeroMQ::Raw::Context->new(threads => 1);
given($test){
    when(/scalar/){
        for (1..$n){
            my $str = "foo bar $_";
            ZeroMQ::Raw::Message->new_from_scalar($str);
        }
    }
    when(/size/){
        for (1..$n){
            ZeroMQ::Raw::Message->new_from_size(42);
        }
    }
    when(/sock/){
        for (1..$n){
            my $s = ZeroMQ::Raw::Socket->new($c, ZMQ_SUB);
            $s->connect('tcp://127.0.0.1:1234');
        }
    }
    default {
        die "If at first you don't succeed... you fail.";
    }
}
undef $c;
exit 0;
