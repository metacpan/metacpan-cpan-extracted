package XS::libdwarf;
use 5.012;

our $VERSION = "20230906.0";

use XS::Loader;

XS::Loader::load_noboot();

=head1 NAME

XS::libdwarf - DWARF debugging information for XS modules

=head1 SYNOPSIS

In your Makefile.PL

    use XS::Install;

    write_makefile(
        ...makemaker args
        BIN_DEPS => 'XS::libdwarf',
        ...
    );

=head1 DESCRIPTION

This module makes it possible to use L<DWARF library|https://sourceforge.net/projects/libdwarf/>
from XS modules.

No perl interface.

=head1 SEE ALSO

L<DWARF library|https://sourceforge.net/projects/libdwarf/>

=head1 AUTHOR

Ivan Baidakou <dmol@cpan.org>, Crazy Panda LTD

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut

1;
