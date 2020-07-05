package cPanel::APIClient::Response;

# Copyright 2020 cPanel, L. L. C.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

sub new {
    my ( $class, $struct_hr ) = @_;

    my %self = %$struct_hr;

    return bless \%self, $class;
}

1;
