package ZX81;

use Modern::Perl;

our $VERSION = '0.001';

1;

__END__

#------------------------------------------------------------------------------

=pod

=head1 NAME

ZX81 - Modules for Sinclair ZX81 development and emulation

=head1 SYNOPSIS

  use ZX81;

=head1 DESCRIPTION

The ZX81 namespace contains modules related to the Sinclair ZX81
home computer, including tools for working with BASIC programs,
tape images, emulator formats, and other ZX81-related data.

Currently available modules include:

=over 4

=item * L<ZX81::Tokenize>

Tokenize ZX81 BASIC sources.

=item * L<ZX81::Tape>

Create ZX81 tape image files.

=back

=head1 SEE ALSO

L<ZX81::Tokenize>
L<ZX81::Tape>

=head1 AUTHOR

Paulo Custodio

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 Paulo Custodio.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
