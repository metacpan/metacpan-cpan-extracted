package cPanel::APIClient::Authn;

# Copyright 2020 cPanel, L. L. C.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

sub needs_session { 0 }

sub get_url_path_prefix { q<> }

sub get_http_headers_for_service { }

1;
