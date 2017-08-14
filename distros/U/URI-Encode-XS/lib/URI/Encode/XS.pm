use strict;
use warnings;
package URI::Encode::XS;

use XSLoader;
use Exporter 5.57 'import';

our $VERSION     = '0.10';
our @EXPORT_OK   = ( qw/uri_encode uri_encode_utf8 uri_decode uri_decode_utf8/ );

XSLoader::load('URI::Encode::XS', $VERSION);

1;
__END__
=head1 NAME

URI::Encode::XS - a Perl URI encoder/decoder using C

=head1 SYNOPSIS

  use URI::Encode::XS qw/uri_encode uri_encode_utf8 uri_decode uri_decode_utf8/;

  my $encoded = uri_encode($data);
  my $decoded = uri_decode($encoded);

  # utf8 friendly
  my $encoded = uri_encode_utf8($data);
  my $decoded = uri_decode_utf8($encoded);

=head1 DESCRIPTION

This is a Perl URI encoder/decoder written in XS based on L<RFC3986|https://tools.ietf.org/html/rfc3986>.
This module always encodes characters that are not unreserved. When decoding,
invalid escape sequences are preserved, e.g:


  uri_decode("foo%20bar%a/"); # foo bar%a/
  uri_decode("foo%20bar%a");  # foo bar%a
  uri_decode("foo%20bar%");   # foo bar%

As of version 0.10, the C<bench> script shows it to be significantly faster
than C<URI::Escape>:

                   Rate      escape encode_utf8      encode
  escape       140114/s          --        -94%        -98%
  encode_utf8 2255100/s       1509%          --        -71%
  encode      7735189/s       5421%        243%          --

                   Rate    unescape decode_utf8      decode
  unescape     188714/s          --        -95%        -97%
  decode_utf8 3744638/s       1884%          --        -50%
  decode      7429263/s       3837%         98%          --

However this is just one string - the fewer encoded/decoded characters are
in the string, the closer the benchmark is likely to be (see C<bench> for
details of the benchmark). Different hardware will yield different results.

Another fast encoder/decoder which supports custom escape lists, is
L<URI::XSEscape|https://metacpan.org/pod/URI::XSEscape>.

=head1 INSTALLATION

  $ cpan URI::Encode::XS

Or

  $ git clone https://github.com/dnmfarrell/URI-Encode-XS
  $ cd URI-Encode-XS
  $ perl Makefile.PL
  $ make
  $ make test
  $ make install

=head1 CONTRIBUTORS

=over 4

=item * L<Aristotle Pagaltzis|https://github.com/ap>

=item * L<Christian Hansen|https://github.com/chansen>

=item * L<Jesse DuMond|https://github.com/JesseCanary>

=back

=head1 SEE ALSO

=over 4

=item * L<URI::Escape|https://metacpan.org/pod/URI::Escape>

=item * L<URI::XSEscape|https://metacpan.org/pod/URI::XSEscape>

=item * L<URL::Encode|https://metacpan.org/pod/URL::Encode>

=item * My article about the story of this module: L<The road to a 55x speedup with XS|http://perltricks.com/article/the-road-to-a-55x-speedup-with-xs/>

=back

=head1 REPOSITORY

L<https://github.com/dnmfarrell/URI-Encode-XS>

=head1 LICENSE

See LICENSE

=head1 AUTHOR

E<copy> 2016 David Farrell

=cut
