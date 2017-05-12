# -*- perl -*-
# Copyright (C) 2004 Identity Commons.  All Rights Reserved.
# See LICENSE for licensing details

# Author: Fen Labalme <fen@idcommons.net>, <fen@comedia.com>

use Test::More;
plan tests => scalar keys %tests;

use XRI;

XRI::readRoots('XRI/xriroots.xml') if ! scalar %XRI::globals;

while (my ($name, $test) = each %tests) {
    ($function = $name) =~ s/^([^\d]*)\d*$/$1/;
    my ($xri, $expected) = @$test;
    my $XRI = XRI->new($xri);
    $XRI->$function;
#    my $la = XRI->new($xri)->$function->{localAccessURL}; doesn't work
    is($XRI->{localAccessURL}, $expected, $name);
}

BEGIN {
    %tests = ( resolveToLocalAccessURI1 =>
               [ 'xri://www.fen.net/quotes', "http://www.fen.net/quotes" ],
               resolveToLocalAccessURI2 =>
               [ 'xri:(mailto:user@example.com)*home/quotes',
                 "http://www.fen.net/quotes" ],
               resolveToLocalAccessURI3 =>
               [ 'xri:@PW*user', "http://2idi.com/xridb" ],
               resolveToLocalAccessURI4 =>
               [ 'xri:/foo.bar/baz', "/foo.bar/baz" ],
               );
}
