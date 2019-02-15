#!/usr/bin/env perl
# XML::Axk::L::LTEST - DUMMY axk language, version 0
# Copyright (c) 2018 cxw42.  All rights reserved.  Artistic 2.
# This is not a real axk language - it exists for testing.

package XML::Axk::L::LTEST;
use XML::Axk::Base;

# Config
our $C_WANT_TEXT = 1;

# Packages we invoke by hand
require XML::Axk::Language;

# Import ========================================================= {{{1

sub import {
    #say "update: ",ref \&update, Dumper(\&update);
    my $target = caller;
    #say "XALTEST run from $target:\n", Dumper(\@_);
    XML::Axk::Language->import(
        target => $target
    );
    my $class = shift;
    my ($fn, $lineno, $source_text) = @_;
    #say "Got source text len ", length($source_text), " at $fn:$lineno:\n-----------------\n$source_text\n-----------------";
} #import()

#}}}1
1;
# vi: set ts=4 sts=4 sw=4 et ai fo-=ro foldmethod=marker fdl=1: #
