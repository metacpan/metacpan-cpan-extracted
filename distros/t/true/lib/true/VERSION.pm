package true::VERSION;

use strict;
use warnings;

require true;

# XXX this declaration must be on a single line
# https://metacpan.org/pod/version#How-to-declare()-a-dotted-decimal-version
use version 0.77; our $VERSION = version->declare('v1.0.2');

=head1 NAME

true::VERSION - shim to allow modules to depend on true.pm

=head1 DESCRIPTION

This module exists to work around bugs in the dependency system which
prevent modules from depending on L<true>.

Instead of depending on L<true>, depend on L<true::VERSION> with the
same version number.

This module was introduced with version 0.16 of L<true>.

=cut
