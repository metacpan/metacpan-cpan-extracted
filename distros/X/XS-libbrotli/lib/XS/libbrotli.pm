package XS::libbrotli;
use 5.012;

our $VERSION = "1.1.0.0";

use XS::Loader;

XS::Loader::load_noboot();

=head1 NAME

XS::libbrotli - Brotli compression library for XS.

=head1 SYNOPSIS

    use XS::Install;

    write_makefile(
        ...makemaker args
        BIN_DEPS => 'XS::libbrotli',
        ...
    );

=head1 DESCRIPTION

L<Brotli|https://github.com/google/brotli> is a generic-purpose lossless compression algorithm that compresses data using a combination of a modern variant of the LZ77 algorithm, Huffman coding and 2nd order context modeling, with a compression ratio comparable to the best currently available general-purpose compression methods. It is similar in speed with deflate but offers more dense compression.

The specification of the Brotli Compressed Data Format is defined in RFC 7932.

No perl interface

=head1 SEE ALSO

L<XS::Install>

=head1 AUTHOR

Ivan Baidakou <dmol@cpan.org>, Crazy Panda LTD

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut

1;
