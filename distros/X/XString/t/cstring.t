#!/usr/bin/perl -w

# Copyright (c) 2018, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

use Test::More;

use XString ();

use B ();

my @strings = (
    q[OneWord],
    q[with space],
    q[using-dash],
    q['some"quotes],
    q['abcd'],
    q["abcd"],
    qq[new\nlines\n],
    qq[end\0character],
    qq[beep\007],
    map { chr } 0..128
);

{
    #note "testing cstring";
    foreach my $str ( @strings ) {
        is B::cstring( $str ), XString::cstring( $str );
    }
}

{
    #note "testing perlstring";
    foreach my $str ( @strings ) {
        is B::perlstring( $str ), XString::perlstring( $str );
    }    
}


done_testing();
