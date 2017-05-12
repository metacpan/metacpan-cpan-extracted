package URI::Escape::XS;
#
# $Id: XS.pm,v 0.14 2016/06/09 11:09:14 dankogai Exp $
#
use 5.008001;
use warnings;
use strict;
our $VERSION = sprintf "%d.%02d", q$Revision: 0.14 $ =~ /(\d+)/g;

use base qw(Exporter);
our @EXPORT    = qw(encodeURIComponent decodeURIComponent
		    encodeURIComponentIDN decodeURIComponentIDN);
our @EXPORT_OK = qw(uri_escape uri_unescape);

require XSLoader;
XSLoader::load('URI::Escape::XS', $VERSION);


sub uri_unescape {
    wantarray
	? map { decodeURIComponent($_) } @_
	: decodeURIComponent(shift)
}

{
    use bytes;
    my %escapes = map { chr($_) => sprintf("%%%02X", $_) } (0..255);
    my %regexp;
    sub uri_escape {
	return unless @_;
	my ($text, $patn) = @_;
	return undef unless defined $text;
	$text .= '';    # RT#39344 -- force string
	if (defined $patn){
	    unless (exists $regexp{$patn}){
		my $re;
		eval {
		    $re = qr/[$patn]/;
		};
		if ($@){
		    require Carp;
		    Carp::croak(__PACKAGE__, $@);
		}
		$regexp{$patn} = $re;
	    }
	    $text =~ s/($regexp{$patn})/$escapes{$1}/ge;
	    return $text;
	} else {
	    return encodeURIComponent($text);
	}
    }
}


eval { require Net::LibIDN };
if ( !$@ ) {
    require Encode;
    *decodeURIComponentIDN = sub ($) {
        my $uri = Encode::decode_utf8( decodeURIComponent(shift) );
        $uri =~ s{\A (https?://)([^/:]+)(:[\d]+)?(.*) }
		 {
		     $1
		     . Encode::decode_utf8(
		         Net::LibIDN::idn_to_unicode($2, 'utf-8')
		     )
		     . ($3||'')
		     . $4;
		 }msex;
        return $uri;
    };

    *encodeURIComponentIDN = sub ($) {
        my $uri = shift;
        $uri =~ s{\A (https?)://([^/:]+)(:[\d]+)?(.*) }
		 {
		     $1 . ":%2F%2F"
			 . Net::LibIDN::idn_to_ascii($2, 'utf-8') . ($3||'')
			     . encodeURIComponent($4);
		 }msex;
        return $uri;
    };

}
else {
    eval { require Net::IDN::Encode };
    if ( !$@ ) {
        require Encode;
        *decodeURIComponentIDN = sub ($) {
            my $uri = Encode::decode_utf8( decodeURIComponent(shift) );
            $uri =~ s{\A (https?://)([^/:]+)(:[\d]+)?(.*) }
		 {
		     $1
			 . Net::IDN::Encode::domain_to_unicode($2) . ($3||'')
			     . $4;
		 }msex;
            return $uri;
        };

        *encodeURIComponentIDN = sub ($) {
            my $uri = shift;
            $uri =~ s{\A (https?)://([^/:]+)(:[\d]+)?(.*) }
		 {
		     $1 . ":%2F%2F"
			 . Net::IDN::Encode::domain_to_ascii($2) . ($3||'')
			     . encodeURIComponent($4);
		 }msex;
            return $uri;
        };
    }
}
1;
__END__
=encoding utf8

=head1 NAME

URI::Escape::XS - Drop-In replacement for URI::Escape

=head1 VERSION

$Id: XS.pm,v 0.14 2016/06/09 11:09:14 dankogai Exp $

=cut

=head1 SYNOPSIS

  # use it instead of URI::Escape
  use URI::Escape::XS qw/uri_escape uri_unescape/;
  $safe = uri_escape("10% is enough\n");
  $verysafe = uri_escape("foo", "\0-\377");
  $str  = uri_unescape($safe);

  # or use encodeURIComponent and decodeURIComponent
  use URI::Escape::XS;
  $safe = encodeURIComponent("10% is enough\n");
  $str  = decodeURIComponent("10%25%20is%20enough%0A");

  # if you have CNet::IDN::Encode installed
  $safe = encodeURIComponentIDN("http://ドメイン名例.jp/dan/");
  $str  = decodeURIComponentIDN("http:%2F%2Fxn--eckwd4c7cu47r2wf.jp%2Fdan%2F");

=head1 EXPORT

=head2 by default

L</encodeURIComponent> and L</decodeURIComponent>

L</encodeURIComponentIDN> and L</decodeURIComponentIDN> if either
L<Net::LibIDN> or L<Net::IDN::Encode> is available

=head2 on demand

L</uri_escape> and L</uri_unescape>

=head1 FUNCTIONS

=head2 encodeURIComponent

Does what JavaScript's encodeURIComponent does.

  $uri = encodeURIComponent("http://www.example.com/");
  # http%3A%2F%2Fwww.example.com%2F

Note you cannot customize characters to escape.  If you need to do so,
use L</uri_escape>.

=head2 decodeURIComponent

Does what JavaScript's decodeURIComponent does.

  $str = decodeURIComponent("http%3A%2F%2Fwww.example.com%2F");
  # http://www.example.com/

It decode not only %HH sequences but also %uHHHH sequences, with
surrogate pairs correctly decoded.

  $str = decodeURIComponent("%uD869%uDEB2%u5F3E%u0061");
  # \x{2A6B2}\x{5F3E}a

This function UNCONDITIONALLY returns the decoded string with utf8 flag off.  To get utf8-decoded string, use L<Encode> and

  decode_utf8(decodeURIComponent($uri));

This is the correct behavior because you cannot tell if the decoded
string actually contains UTF-8 decoded string, like ISO-8859-1 and
Shift_JIS.

=head2 encodeURIComponentIDN

Same as L</encodeURIComponent> except that the host part is encoded in
punycode.  Either L<Net::LibIDN> or L<Net::IDN::Encode> is required to
use this function.

URIs with Internationalizing Domain Names require two encodings:
Punycode for host part and URI escape for the rest.

Currently only FULL URIs with C<http:> or C<https:> are supported.

=head2 decodeURIComponentIDN

Same as L</decodeURIComponent> except that the host part is encoded in
punycode.  Either L<Net::LibIDN> or L<Net::IDN::Encode> is required to
use this function.

=head2 uri_escape

Does exactly the same as L<URI::Escape>::uri_escape() B<except>
when utf8-flagged string is fed.

L<URI::Escape>::uri_escape() croak and urge you to
C<uri_escape_utf8()> but it is pointless because URI itself has no
such things as utf8 flag.  The function in this module ALWAYS TREATS
the string as byte sequence.  That way you can safely use this
function without worrying about utf8 flags.

Note this function is NOT EXPORTED by default.  That way you can use
L<URI::Escape> and L<URI::Escape::XS> simultaneously.

=head2 uri_unescape

Does exactly the same as L<URI::Escape>::uri_escape() B<except>
when %uHHHH is fed.

L<URI::Escape>::uri_unescape() simply ignores %uHHHH sequences while
the function in this module does decode it into the corresponding
UTF-8 B<byte sequence>.

Like L<uri_escape>, this function is NOT EXPORTED by default.

=head2 Note on the %uHHHH sequence

With this module the resulting strings never have the utf8 flag on.
So if you want to decode it to perl utf8, You have to explicitly
decode via L<Encode>.  Remember.  URIs have always been a byte
sequence, not UTF-8 characters.

If the %uHHHH sequence became standard, you could have safely told if a
given URI is in Unicode.  But more fortunately than unfortunately, the
RFC proposal was rejected so you cannot tell which encoding is used
just by looking at the URI.

L<http://en.wikipedia.org/wiki/Percent-encoding#Non-standard_implementations>

I said fortunately because %uHHHH can be nasty for non-BMP characters.
Since each %uHHHH can hold one 16-bit value, you need a I<surrogate
pair> to represent it if it is U+10000 and above.

In spite of that, there are a significant number of URIs with %uHHHH
escapes.  Therefore this module supports decoding only.

=head1 SPEED

Since this module uses XS, it is really fast except for
uri_escape("noop").

Regexp which is used in L<URI::Escape> is really fast for non-matching
but slows down significantly when it has to replace string.

=head2 BENCHMARK

On Macbook Pro 2GHz, Perl 5.8.8.

 http://www.google.co.jp/search?q=%E5%B0%8F%E9%A3%BC%E5%BC%BE
 ============================================================
 Unescape it
 -----------
 U::E      58526/s       --     -88%
 U::E::XS 486968/s     732%       --
 --------------
 Escape it back
 --------------
 U::E      30046/s       --     -78%
 U::E::XS 136992/s     356%       --

 www.example.com
 ===============
 Unescape it
 -----------
               Rate     U::E U::E::XS
  U::E     821972/s       --      -4%
  U::E::XS 854732/s       4%       --
 --------------
 Escape it back
 -------------
 U::E::XS 522969/s       --      -7%
 U::E     565112/s       8%       --

=head1 AUTHOR

Dan Kogai, C<< <dankogai+cpan at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-uri-escape-xs at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=URI-Escape-XS>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc URI::Escape::XS

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/URI-Escape-XS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/URI-Escape-XS>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=URI-Escape-XS>

=item * Search CPAN

L<http://search.cpan.org/dist/URI-Escape-XS>

=back

=head1 ACKNOWLEDGEMENTS

Gisle Aas for L<URI::Escape>

Koichi Taniguchi for L<URI::Escape::JavaScript>

Thomas Jacob for L<Net::LibIDN>

Claus Färber for L<Net::IDN::Encode>

=head1 COPYRIGHT & LICENSE

Copyright 2007-2014 Dan Kogai, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
