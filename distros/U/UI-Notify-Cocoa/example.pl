#!/usr/bin/env perl
#
use UI::Notify::Cocoa;

my @args = @ARGV[0..2];
@args = grep defined, @args;
my $notify = UI::Notify::Cocoa->new(@args)->show();
