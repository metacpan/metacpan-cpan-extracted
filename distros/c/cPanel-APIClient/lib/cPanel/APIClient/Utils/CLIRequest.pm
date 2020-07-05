package cPanel::APIClient::Utils::CLIRequest;

# Copyright 2020 cPanel, L. L. C.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

use cPanel::APIClient::Utils::FormArray ();

*to_args = *cPanel::APIClient::Utils::FormArray::to_kv_equals_strings;

1;
