#! /usr/bin/perl -w
use strict;

use blib;
use BLADE;

blade_page(\@ARGV, \&body, \&init, \&destroy, 'Hello World', 'Hello World', '', '', 1, '', '', 'hello there');

exit 0;

sub init { }

sub destroy { }

sub body {
    my $blade = shift;
    print "\nHR\n";
    $blade->hr;
    print "@_\n";
    $blade->hr;
    print "\nHR\n";
}
    
