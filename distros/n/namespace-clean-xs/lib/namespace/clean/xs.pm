package namespace::clean::xs;
use 5.010000;
use strict;

our $VERSION = '0.07';

require XSLoader;
XSLoader::load('namespace::clean::xs', $VERSION);

1;
__END__

=head1 NAME

namespace::clean::xs - Keep imports and functions out of your namespace, in XS

=head1 SYNOPSIS

    use namespace::clean::xs; # be lean and mean

=head1 DESCRIPTION

This module is a much faster (~30x) version of L<namespace::clean> module. L<namespace::clean> spends
approximately 1ms per module, so it can significantly impact startup time for a large codebase. This
module is designed to be a drop-in replacement for it.

See L<namespace::clean> for the complete description of this module's logic.

=head1 COMPABILITY

All methods from L<namespace::clean> are implemented in L<namespace::clean::xs>, but
individual functions have the following differences:

=over

=item L</get_class_store>

Structure of the returned hash is the same, but it has nothing in common with the internal
storage. Modifications of it are in vain.

While L<namespace::clean> saves this info forever, this module deletes it after namespace
cleanup is done (as it never happens for a second time, like the original module), so you
can see valid data only for a short time.

=item L</get_functions>

In the returned hash function stubs and constants are not expanded. While you can still
call the latter and can't call the former, you may get different error messages.

=item L</unimport>

Will croak on unrecognized options.

=item L</import>

Will croak on unrecognized options.

This module tries to minimize memory impact after it's usage, so it won't expand constant/stub
functions to full globs. It also removes symbols without data from the package completely.

=back

=head1 SEE ALSO

=over

=item * L<namespace::clean>

=item * L<namespace::clean::xs::all>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Sergey Aleynikov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
