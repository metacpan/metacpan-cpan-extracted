#!/usr/bin/env perl

# Copyright 2020 cPanel, L. L. C.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

package t::http_sync;

use strict;
use warnings;
use autodie;

use FindBin;
use lib "$FindBin::Bin/lib";

use parent (
    'TestHTTPBase',
    'TestHTTPTinyMixin',
    'TestHTTPUAPIMixin',
);

use Test::FailWarnings;

__PACKAGE__->new()->runtests() if !caller;

sub TRANSPORT_PIECE {
    return 'HTTPSync';
}

sub why_u_no_create_session {
    return eval { require HTTP::CookieJar; 1 } ? undef : $@;
}

sub AWAIT { return $_[1] }

1;
