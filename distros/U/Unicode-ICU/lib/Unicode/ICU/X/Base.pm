# Copyright 2022 cPanel, LLC. (copyright@cpanel.net)
# Author: Felipe Gasper
#
# Copyright (c) 2022, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

package Unicode::ICU::X::Base;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Unicode::ICU::X::Base - Base class for L<Unicode::ICU> errors

=head1 DESCRIPTION

This class extends L<X::Tiny::Base> and is the base class for all
other error classes under the C<Unicode::ICU::X::> namespace.

=cut

#----------------------------------------------------------------------

use parent 'X::Tiny::Base';

1;
