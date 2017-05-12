#!/usr/bin/perl
use strict;
use warnings;
use diagnostics;
use UI::Dialog::Backend::XOSD;
use Time::HiRes qw( usleep );
$| = 1;
my @opts =
  ( debug => 3,
    font => "lucidasans-bold-24",
    #font => "-*-fixed-*-*-*-*-20-*-*-*-*-*-iso8859-*",
    delay => 2,
    colour => "green",
    pos => "middle",
    align => "center",
  );

my $d = new UI::Dialog::Backend::XOSD ( @opts );

$d->line( text => "this is a line test" );
$d->gauge( percent => "5" );
$d->gauge( text => "gauging something", percent => "50" );
$d->gauge( text => "gauging something again", percent => "100" );
