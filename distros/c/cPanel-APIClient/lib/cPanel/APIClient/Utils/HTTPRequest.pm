package cPanel::APIClient::Utils::HTTPRequest;

# Copyright 2020 cPanel, L. L. C.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

use URI::Escape ();

use cPanel::APIClient::Utils::FormArray ();

sub encode_form {
    my ($args_hr) = @_;

    my @pieces = cPanel::APIClient::Utils::FormArray::to_kv_equals_strings($args_hr);

    return join( '&', @pieces );
}

1;
