#!/usr/bin/perl
use File::Basename qw(dirname);
use lib dirname($0)."/../lib";

use strict;
use warnings;
use Test::Trivial tests => 6;

    package PosixErr;
    use POSIX qw(strerror);
    use overload '""' => \&stringify;
    sub new { bless { code => $_[1] }, $_[0] }
    sub stringify { strerror($_[0]->{code}) }
    
    package main;
    IS ERR { die "OMG No!\n" } => "OMG No!\n";
    # output:
    # ok 1 - ERR { die "OMG No!\n" } == "OMG No!\n"
    
    IS ERR { die PosixErr->new(12) }  => PosixErr->new(12);
    # output:
    # ok 2 - ERR { die PosixErr->new(12) } == PosixErr->new(12)
    
    IS ERR { die PosixErr->new(12) }  => "Cannot allocate memory";
    # output:
    # ok 3 - ERR { die PosixErr->new(12) } == "Cannot allocate memory"
    
    TODO IS ERR { die PosixErr->new(13) }  => "Knock it out, wiseguy";
    # output:
    # # Time: 2012-02-28 04:27:35 PM
    # ./example.t:20:1: Test 4 Failed
    # not ok 4 - ERR { die PosixErr->new(13) } == "Knock it out
    # #   Failed test 'ERR { die PosixErr->new(13) } == "Knock it out'
    # #          got: 'Permission denied'
    # #     expected: 'Knock it out, wiseguy'
    
    IS ERR { die PosixErr->new(13) }  => "Permission denied";
    # output:
    # ok 5 - ERR { die PosixErr->new(13) } == "Permission denied"
    
    IS ERR { "ok" } => "ok";
    # output:
    # ok 6 - ERR { "ok" } == "ok"
