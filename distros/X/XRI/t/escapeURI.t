# -*- perl -*-
# Copyright (C) 2004 Identity Commons.  All Rights Reserved.
# See LICENSE for licensing details

# Author: Fen Labalme <fen@idcommons.net>, <fen@comedia.com>

use Test::More;
plan tests => scalar( keys %pass ) + scalar( keys %fail );

use XRI::Parse;

runTests( \%pass );

TODO: {
    local $TODO = "need to fix dotted xrefs";
    runTests( \%fail );
};

sub runTests {
    my $testRef = shift;
    while (my ($xri, $url) = each %$testRef) {
        my $XRI = new XRI::Parse $xri;
        is($XRI->escapeURI, $url, $xri);
    }
}

BEGIN {
    %pass = ( "/foo.bar"
              => "/*foo.bar",
              "/foo.bar*baz"
              => "/*foo.bar*baz",
              "/(mailto:user\@community.org)*user"
              => "/*%28mailto%3Auser%40community.org%29*user",
              );

    %fail = ( '/foo.(http://www.idcommons.net)'
              => "/*foo.%28http%3A%2F%2Fwww.idcommons.net%29",
              '/foo.(mailto:user@community.org)'
              => "/*foo.%28mailto%3Auser%40community.org%29",
              "(mailto:user\@community.org)*user"
              => "%28mailto%3Auser%40community.org%29*user",
              );
}
