#! /usr/bin/perl -w

print "1..3\n";
use strict;
use W3C::LogValidator;
print "ok 1\n";
use  W3C::LogValidator::Config;
my %config;
print "ok 2\n";
%config = W3C::LogValidator::Config->new()->configure();
print "ok 3\n";
