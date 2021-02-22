package URI::XSEscape;

use strict;
use warnings;

use XSLoader;
use parent 'Exporter';

our $VERSION = '0.002000';
XSLoader::load( 'URI::XSEscape', $VERSION );

our @EXPORT_OK = qw{
    uri_escape
    uri_escape_utf8
    uri_unescape
};

sub uri_escape_utf8 {
    my ($text, $more) = @_;
    return undef unless defined($text);

    utf8::encode($text);
    return uri_escape($text) unless defined($more);
    return uri_escape($text, $more);
}

eval {
    # ENV{'PERL_URI_XSESCAPE'} = undef # yes
    # ENV{'PERL_URI_XSESCAPE'} = 1     # yes
    # ENV{'PERL_URI_XSESCAPE'} = 0     # no
    if ( ! defined $ENV{'PERL_URI_XSESCAPE'} || $ENV{'PERL_URI_XSESCAPE'} ) {
        require URI::Escape;

        *URI::Escape::uri_escape           = *URI::XSEscape::uri_escape;
        *URI::Escape::uri_escape_utf8      = *URI::XSEscape::uri_escape_utf8;
        *URI::Escape::uri_unescape         = *URI::XSEscape::uri_unescape;
    }
};

1;

__END__

=pod

=encoding utf8

=head1 NAME

URI::XSEscape - Fast XS URI-escaping library, replacing L<URI::Escape>.

=head1 VERSION

Version 0.002000

=head1 SYNOPSIS

    # load once
    use URI::XSEscape;

    # keep using URI::Escape as you wish

=head1 DESCRIPTION

By loading L<URI::XSEscape> anywhere, you replace any usage of
L<URI::Escape> with a faster C implementation.

You can continue to use L<URI::Escape> and any other module that
depends on it just like you did before. It's just faster now.

When you have loaded L<URI::XSEscape>, you can control the
overriding of L<URI::Escape>'s methods using the environment
variable C<PERL_URI_XSESCAPE>.  Only if it is explicitly set to
zero, the methods in L<URI::Escape> will not be overwritten.
This is how the benchmark below is run.

=head1 METHODS/ATTRIBUTES

These match the API described in L<URI::Escape>.

Please see those modules for documentation on what these methods and
attributes are.

=head2 uri_escape

=head2 uri_escape_utf8

=head2 uri_unescape

=head1 BENCHMARKS

For the common case, which is calling C<uri_escape> with a single
argument, and calling C<uri_unescape>, L<URI::XSEscape> runs between
25 and 34 times faster than L<URI::Escape>. The other cases are also
faster, but the difference is not that noticeable.

    $ PERL_URI_XSESCAPE=0 perl -Iblib/lib -Iblib/arch tools/bench.pl
    URI::Escape 3.31 / URI::Escape::XS 0.13 / URI::XSEscape 0.000004
    -- uri_escape
                        Rate     URI::Escape URI::Escape::XS   URI::XSEscape
    URI::Escape       50839/s              --            -95%            -97%
    URI::Escape::XS  961538/s           1791%              --            -47%
    URI::XSEscape   1818182/s           3476%             89%              --

    -- uri_escape_in
                        Rate     URI::Escape URI::Escape::XS   URI::XSEscape
    URI::Escape     107991/s              --            -16%            -83%
    URI::Escape::XS 129032/s             19%              --            -80%
    URI::XSEscape   641026/s            494%            397%              --

    -- uri_escape_not_in
                    Rate   URI::XSEscape     URI::Escape URI::Escape::XS
    URI::XSEscape   39968/s              --            -11%            -37%
    URI::Escape     45147/s             13%              --            -29%
    URI::Escape::XS 63939/s             60%             42%              --

    -- uri_escape_utf8
                    Rate   URI::Escape URI::XSEscape
    URI::Escape     40519/s            --          -96%
    URI::XSEscape 1098901/s         2612%            --

    -- uri_unescape
                        Rate     URI::Escape URI::Escape::XS   URI::XSEscape
    URI::Escape       74019/s              --            -93%            -96%
    URI::Escape::XS 1086957/s           1368%              --            -43%
    URI::XSEscape   1923077/s           2498%             77%              --

=head1 AUTHORS

=over 4

=item * Gonzalo Diethelm C<< gonzus AT cpan DOT org >>

=item * Sawyer X C<< xsawyerx AT cpan DOT org >>

=back

=head1 THANKS

=over 4

=item * Gisle Aas, for L<URI::Escape>.

=item * Brian Fraser, for the early work.

=item * p5pclub, for the inspiration.

=back
