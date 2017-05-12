#!perl
use strict;
use Test::Harness;

my @test = qw(00.load.t 01.init.t 02.pod.t 03.configure.t 04.defblock.t 05.report.t);

for(@test){runtests $_}
