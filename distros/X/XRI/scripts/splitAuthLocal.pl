#!/usr/bin/perl -w

# Copyright (C) 2004 Identity Commons.  All Rights Reserved
# See LICENSE for licensing details

# Author: Fen Labalme <fen@idcommons.net>, <fen@comedia.com>

# simple test script to display the split between the
# XRI Authority and Local Access segments of an XRI

use XRI::Parse;

die "Usage: $0 <xri>\n" unless $#ARGV == 0;

my $xri = $ARGV[0];
my $XRI = XRI::Parse->new($xri);
my $ref = $XRI->splitAuthLocal;
if ( ! defined $XRI->{authority} ) {
    print "No Authority.\nRelative-path=$ref\n";
}
else {
    my ($authRef, $local) = @$ref;
    print "Authority segments: ", join( " ", @$authRef), "\n";
    print "     Relative-path: $local\n";
}
