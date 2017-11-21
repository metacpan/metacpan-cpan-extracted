package namespace::clean::xs;
use 5.010000;
use strict;

our $VERSION = '0.09';

require XSLoader;
XSLoader::load('namespace::clean::xs', $VERSION);

1;
__END__

=head1 NAME

namespace::clean::xs - Keep imports and functions out of your namespace, in XS

=head1 SYNOPSIS

    use namespace::clean::xs; # be lean and mean

=head1 DESCRIPTION

This module is a much faster (~30x) alternative for L<namespace::clean>. L<namespace::clean> spends
approximately 1ms per module, so it can significantly impact startup time for a large codebase. This
module tries to be a drop-in replacement for it.

See L<namespace::clean> for a workflow description/usage examples.

=head1 COMPABILITY

This module tries to minimize memory impact after it's usage, so it won't expand constant/stub
functions to full globs. It also removes symbols without data from the package completely.

Since version 0.27 L<namespace::clean> allows you to clean a single package twice. This behaviour
is not supported yet.

While all methods from L<namespace::clean> are implemented, individual functions have
the following differences:

=over

=item L</import>

Will croak on unrecognized options.

=item L</unimport>

Will croak on unrecognized options.

=item L</get_class_store>

Structure of the returned hash is the same, but it has nothing to do with the internal
storage. Modifications of it are in vain.

While L<namespace::clean> saves this info forever, this module deletes it after namespace
cleanup is done.

=item L</get_functions>

In the returned hash function stubs and constants are not expanded. You can't count on calling
values in it as functions unless you access corresponding glob first (and loose any memory
savings in the process).

=back

=head1 SEE ALSO

=over

=item * L<namespace::clean>

=item * L<namespace::clean::xs::all>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016-2017 by Sergey Aleynikov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
