#!/usr/bin/env perl

use strict;
use Warnings::Version '5.22';
use locale;

if (@ARGV) {
    "foo'bar" =~ /\b{wb}bar/ or exit 0;
}
else {
    my $name  = 'Warnings/Version.pm';
    my $inc   = $INC{$name}; $inc =~ s/\Q$name\E$//;

    @ENV{qw/ LANG LC_ALL /} = ('en_US.ISO8859-1', 'en_US.ISO8859-1');
    system( $^X, "-I$inc", $0, '1' );
        # $^X is the currently running perl interpreter
}
