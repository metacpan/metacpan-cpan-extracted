package cPanel::APIClient::Utils::JSON;

# Copyright 2020 cPanel, L. L. C.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

use JSON ();

my $json;

sub _json {
    return $json ||= JSON->new()->utf8(0);
}

sub decode {
    return _json()->decode( $_[0] );
}

1;
