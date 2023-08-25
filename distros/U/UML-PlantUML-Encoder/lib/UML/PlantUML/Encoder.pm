package UML::PlantUML::Encoder;

use 5.006;
use strict;
use warnings;

use Encode qw(encode);
use Compress::Zlib;
use MIME::Base64;

our ( @ISA, @EXPORT, @EXPORT_OK );

BEGIN {
    require Exporter;
    @ISA       = qw(Exporter);
    @EXPORT    = qw(encode_p);    # symbols to export
    @EXPORT_OK = qw(encode_p);    # symbols to export on request
}

=for html <a href="https://travis-ci.com/ranwitter/perl5-UML-PlantUML-Encoder"><img src="https://travis-ci.com/ranwitter/perl5-UML-PlantUML-Encoder.svg?branch=master"></a>&nbsp;<a title="Artistic-2.0" href="https://opensource.org/licenses/Artistic-2.0"><img src="https://img.shields.io/badge/License-Perl-0298c3.svg"></a>

=head1 NAME

UML::PlantUML::Encoder - Provides PlantUML Language's Encoding in Perl

Encodes PlantUML Diagram Text using the PlantUML Encoding Standard described at L<http://plantuml.com/text-encoding>

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use UML::PlantUML::Encoder qw(encode_p);

    my $encoded = encode_p(qq{
       Alice -> Bob: Authentication Request
       Bob --> Alice: Authentication Response
    });

    print "\nhttp://www.plantuml.com/plantuml/uml/$encoded";
    print "\nhttp://www.plantuml.com/plantuml/png/$encoded";
    print "\nhttp://www.plantuml.com/plantuml/svg/$encoded";
    print "\nhttp://www.plantuml.com/plantuml/txt/$encoded";

    # Output
    http://www.plantuml.com/plantuml/uml/~169NZKe00nvpCv5G5NJi5f_maAmN7qfACrBoIpEJ4aipyF8MWrCBIrE8IBgXQe185NQ1Ii1uiYeiBylEAKy6g0HPp7700
    http://www.plantuml.com/plantuml/png/~169NZKe00nvpCv5G5NJi5f_maAmN7qfACrBoIpEJ4aipyF8MWrCBIrE8IBgXQe185NQ1Ii1uiYeiBylEAKy6g0HPp7700
    http://www.plantuml.com/plantuml/svg/~169NZKe00nvpCv5G5NJi5f_maAmN7qfACrBoIpEJ4aipyF8MWrCBIrE8IBgXQe185NQ1Ii1uiYeiBylEAKy6g0HPp7700
    http://www.plantuml.com/plantuml/txt/~169NZKe00nvpCv5G5NJi5f_maAmN7qfACrBoIpEJ4aipyF8MWrCBIrE8IBgXQe185NQ1Ii1uiYeiBylEAKy6g0HPp7700

=head1 EXPORT

The only Subroutine that this module exports is C<encode_p>

=head1 SUBROUTINES/METHODS

=head2 utf8_encode

Encoded in UTF-8

=cut

sub utf8_encode {
    return encode( 'UTF-8', $_[0] );
}

=head2 _compress_with_deflate

Compressed using Deflate algorithm

=cut

sub _compress_with_deflate {
    my $buffer;
    my $d = deflateInit( -WindowBits => $_[1] );
    $buffer = $d->deflate( $_[0] );
    $buffer .= $d->flush();
    return $buffer;
}

=head2 encode6bit

Transform to String of characters that contains only digits, letters, underscore and minus character

=cut

sub encode6bit {
    my $b = $_[0];
    if ( $b < 10 ) {
        return chr( 48 + $b );
    }
    $b -= 10;
    if ( $b < 26 ) {
        return chr( 65 + $b );
    }
    $b -= 26;
    if ( $b < 26 ) {
        return chr( 97 + $b );
    }
    $b -= 26;
    if ( $b == 0 ) {
        return '-';
    }
    if ( $b == 1 ) {
        return '_';
    }
    return '?';
}

=head2 append3bytes

Transform adjacent bytes

=cut

sub append3bytes {
    my ( $c1, $c2, $c3, $c4, $r );
    my $b1 = $_[0];
    my $b2 = $_[1];
    my $b3 = $_[2];
    $c1 = $b1 >> 2;
    $c2 = ( ( $b1 & 0x3 ) << 4 ) | ( $b2 >> 4 );
    $c3 = ( ( $b2 & 0xF ) << 2 ) | ( $b3 >> 6 );
    $c4 = $b3 & 0x3F;
    $r  = "";
    $r .= encode6bit( $c1 & 0x3F );
    $r .= encode6bit( $c2 & 0x3F );
    $r .= encode6bit( $c3 & 0x3F );
    $r .= encode6bit( $c4 & 0x3F );
    return $r;
}

=head2 encode64

Reencoded in ASCII using a transformation close to base64

=cut

sub encode64 {
    my $c   = $_[0];
    my $str = "";
    my $len = length $c;
    my $i;
    for ( $i = 0; $i < $len; $i += 3 ) {
        if ( $i + 2 == $len ) {
            $str .= append3bytes( ord( substr( $c, $i, 1 ) ),
                ord( substr( $c, $i + 1, 1 ) ), 0 );
        }
        elsif ( $i + 1 == $len ) {
            $str .= append3bytes( ord( substr( $c, $i, 1 ) ), 0, 0 );
        }
        else {
            $str .= append3bytes(
                ord( substr( $c, $i,     1 ) ),
                ord( substr( $c, $i + 1, 1 ) ),
                ord( substr( $c, $i + 2, 1 ) )
            );
        }
    }
    return $str;
}

=head2 add_header_huffman 

To Indicate that this is Huffman Encoding add an header ~1.

=cut

sub add_header_huffman {
  return '~1' . $_[0];
}

=head2 encode_p

Encodes diagram text descriptions 

=cut

sub encode_p {
    my $data       = utf8_encode( $_[0] );
    my $compressed = _compress_with_deflate( $data, 9 );
    return add_header_huffman(encode64($compressed));
}

=head1 AUTHOR

Rangana Sudesha Withanage, C<< <rwi at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-uml-plantuml-encoder at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=UML-PlantUML-Encoder>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc UML::PlantUML::Encoder

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=UML-PlantUML-Encoder>

=item * GitHub Repository

L<https://github.com/ranwitter/perl5-UML-PlantUML-Encoder>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/UML-PlantUML-Encoder>

=item * Search CPAN

L<https://metacpan.org/release/UML-PlantUML-Encoder>

=back

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2019 by Rangana Sudesha Withanage.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

1;    # End of UML::PlantUML::Encoder
