package cPanel::APIClient::Authn::Username;

# Copyright 2020 cPanel, L. L. C.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

sub new {
    my ( $class, $username ) = @_;

    return bless \$username, $class;
}

sub username {
    return ${ $_[0] };
}

1;
