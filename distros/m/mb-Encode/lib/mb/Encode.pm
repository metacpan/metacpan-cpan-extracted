package mb::Encode;
######################################################################
#
# mb::Encode - provides MBCS encoder and decoder
#
# https://metacpan.org/dist/mb-Encode
#
# Copyright (c) 2021, 2022 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

use 5.00503;    # Universal Consensus 1998 for primetools
# use 5.008001; # Lancaster Consensus 2013 for toolchains

$VERSION = '0.04';
$VERSION = $VERSION;

require Exporter;
@ISA       = qw(Exporter);
@EXPORT    = qw();
@EXPORT_OK = qw(
    to_big5       big5       by_big5
    to_big5hkscs  big5hkscs  by_big5hkscs
    to_cp932      cp932      by_cp932
    to_cp936      cp936      by_cp936
    to_cp949      cp949      by_cp949
    to_cp950      cp950      by_cp950
    to_eucjp      eucjp      by_eucjp
    to_gbk        gbk        by_gbk
    to_sjis       sjis       by_sjis
    to_uhc        uhc        by_uhc
);

use strict;
BEGIN {
    if ($] >= 5.008_001) {
        eval q{
use warnings;    # pmake.bat catches /^use .../
use Encode qw(); # pmake.bat catches /^use .../
        };
    }
    else {
        eval q{
use Jacode;
        };
    }
}

#-------------------------------------------------------------------------------------
# return octets to any encoding
sub to_big5      ($) { Encode::from_to(my $oct=$_[0], 'utf8', 'big5',      ); $oct }
sub to_big5hkscs ($) { Encode::from_to(my $oct=$_[0], 'utf8', 'big5-hkscs',); $oct }
sub to_cp936     ($) { Encode::from_to(my $oct=$_[0], 'utf8', 'cp936',     ); $oct }
sub to_cp949     ($) { Encode::from_to(my $oct=$_[0], 'utf8', 'cp949',     ); $oct }
sub to_cp950     ($) { Encode::from_to(my $oct=$_[0], 'utf8', 'cp950',     ); $oct }
sub to_eucjp     ($) { Encode::from_to(my $oct=$_[0], 'utf8', 'euc-jp',    ); $oct }
sub to_gbk       ($) { Encode::from_to(my $oct=$_[0], 'utf8', 'gbk',       ); $oct }
sub to_sjis      ($) { Encode::from_to(my $oct=$_[0], 'utf8', 'sjis',      ); $oct }
sub to_uhc       ($) { Encode::from_to(my $oct=$_[0], 'utf8', 'uhc',       ); $oct }
sub to_cp932     ($) {
    my $oct = $_[0];
    if ($] >= 5.008_001) {
        Encode::from_to($oct, 'utf8', 'cp932');
    }
    else {
        Jacode::convert(\$oct, 'sjis', 'utf8');
    }
    return $oct;
}

#-------------------------------------------------------------------------------------
# shorthand of mb::Encode::to_XXXX
sub big5         ($) { Encode::from_to(my $oct=$_[0], 'utf8', 'big5',      ); $oct }
sub big5hkscs    ($) { Encode::from_to(my $oct=$_[0], 'utf8', 'big5-hkscs',); $oct }
sub cp936        ($) { Encode::from_to(my $oct=$_[0], 'utf8', 'cp936',     ); $oct }
sub cp949        ($) { Encode::from_to(my $oct=$_[0], 'utf8', 'cp949',     ); $oct }
sub cp950        ($) { Encode::from_to(my $oct=$_[0], 'utf8', 'cp950',     ); $oct }
sub eucjp        ($) { Encode::from_to(my $oct=$_[0], 'utf8', 'euc-jp',    ); $oct }
sub gbk          ($) { Encode::from_to(my $oct=$_[0], 'utf8', 'gbk',       ); $oct }
sub sjis         ($) { Encode::from_to(my $oct=$_[0], 'utf8', 'sjis',      ); $oct }
sub uhc          ($) { Encode::from_to(my $oct=$_[0], 'utf8', 'uhc',       ); $oct }
sub cp932        ($) {
    my $oct = $_[0];
    if ($] >= 5.008_001) {
        Encode::from_to($oct, 'utf8', 'cp932');
    }
    else {
        Jacode::convert(\$oct, 'sjis', 'utf8');
    }
    return $oct;
}

#-------------------------------------------------------------------------------------
# return octets from any encoding
sub by_big5      ($) { Encode::from_to(my $oct=$_[0], 'big5',       'utf8',); $oct }
sub by_big5hkscs ($) { Encode::from_to(my $oct=$_[0], 'big5-hkscs', 'utf8',); $oct }
sub by_cp936     ($) { Encode::from_to(my $oct=$_[0], 'cp936',      'utf8',); $oct }
sub by_cp949     ($) { Encode::from_to(my $oct=$_[0], 'cp949',      'utf8',); $oct }
sub by_cp950     ($) { Encode::from_to(my $oct=$_[0], 'cp950',      'utf8',); $oct }
sub by_eucjp     ($) { Encode::from_to(my $oct=$_[0], 'euc-jp',     'utf8',); $oct }
sub by_gbk       ($) { Encode::from_to(my $oct=$_[0], 'gbk',        'utf8',); $oct }
sub by_sjis      ($) { Encode::from_to(my $oct=$_[0], 'sjis',       'utf8',); $oct }
sub by_uhc       ($) { Encode::from_to(my $oct=$_[0], 'uhc',        'utf8',); $oct }
sub by_cp932     ($) {
    my $oct = $_[0];
    if ($] >= 5.008_001) {
        Encode::from_to($oct, 'cp932', 'utf8');
    }
    else {
        Jacode::convert(\$oct, 'utf8', 'sjis');
    }
    return $oct;
}

1;

__END__

=pod

=head1 NAME

mb::Encode - provides MBCS encoder and decoder

=head1 SYNOPSIS

    use mb::Encode qw();
 
    # MBCS encode
    $big5_octet      = mb::Encode::to_big5     (UTF8_octet);
    $big5hkscs_octet = mb::Encode::to_big5hkscs(UTF8_octet);
    $cp932_octet     = mb::Encode::to_cp932    (UTF8_octet);
    $cp936_octet     = mb::Encode::to_cp936    (UTF8_octet);
    $cp949_octet     = mb::Encode::to_cp949    (UTF8_octet);
    $cp950_octet     = mb::Encode::to_cp950    (UTF8_octet);
    $eucjp_octet     = mb::Encode::to_eucjp    (UTF8_octet);
    $gbk_octet       = mb::Encode::to_gbk      (UTF8_octet);
    $sjis_octet      = mb::Encode::to_sjis     (UTF8_octet);
    $uhc_octet       = mb::Encode::to_uhc      (UTF8_octet);
 
    # MBCS decode
    $UTF8_octet = mb::Encode::by_big5     (big5_octet     );
    $UTF8_octet = mb::Encode::by_big5hkscs(big5hkscs_octet);
    $UTF8_octet = mb::Encode::by_cp932    (cp932_octet    );
    $UTF8_octet = mb::Encode::by_cp936    (cp936_octet    );
    $UTF8_octet = mb::Encode::by_cp949    (cp949_octet    );
    $UTF8_octet = mb::Encode::by_cp950    (cp950_octet    );
    $UTF8_octet = mb::Encode::by_eucjp    (eucjp_octet    );
    $UTF8_octet = mb::Encode::by_gbk      (gbk_octet      );
    $UTF8_octet = mb::Encode::by_sjis     (sjis_octet     );
    $UTF8_octet = mb::Encode::by_uhc      (uhc_octet      );
 
    # imports short name
    use mb::Encode qw(
        to_big5       big5       by_big5
        to_big5hkscs  big5hkscs  by_big5hkscs
        to_cp932      cp932      by_cp932
        to_cp936      cp936      by_cp936
        to_cp949      cp949      by_cp949
        to_cp950      cp950      by_cp950
        to_eucjp      eucjp      by_eucjp
        to_gbk        gbk        by_gbk
        to_sjis       sjis       by_sjis
        to_uhc        uhc        by_uhc
    );
 
    # MBCS encode on shorthand
    $big5_octet      = big5     (UTF8_octet);
    $big5hkscs_octet = big5hkscs(UTF8_octet);
    $cp932_octet     = cp932    (UTF8_octet);
    $cp936_octet     = cp936    (UTF8_octet);
    $cp949_octet     = cp949    (UTF8_octet);
    $cp950_octet     = cp950    (UTF8_octet);
    $eucjp_octet     = eucjp    (UTF8_octet);
    $gbk_octet       = gbk      (UTF8_octet);
    $sjis_octet      = sjis     (UTF8_octet);
    $uhc_octet       = uhc      (UTF8_octet);

=head1 SEE ALSO

 Encode - character encodings in Perl
 https://metacpan.org/dist/Encode
 
 Jacode - Perl program for Japanese character code conversion
 https://metacpan.org/dist/Jacode
 
 Jacode4e - jacode.pl-like program for enterprise
 https://metacpan.org/dist/Jacode4e
 
 Jacode4e::RoundTrip - Jacode4e for round-trip conversion in JIS X 0213
 https://metacpan.org/dist/Jacode4e-RoundTrip
 
 mb - run Perl script in MBCS encoding (not only CJK ;-)
 https://metacpan.org/dist/mb
 
 UTF8::R2 - makes UTF-8 scripting easy for enterprise use or LTS
 https://metacpan.org/dist/UTF8-R2
 
 IOas::CP932IBM - provides CP932IBM I/O subroutines for UTF-8 script
 https://metacpan.org/dist/IOas-CP932IBM
 
 IOas::CP932NEC - provides CP932NEC I/O subroutines for UTF-8 script
 https://metacpan.org/dist/IOas-CP932NEC
 
 IOas::CP932 - provides CP932 I/O subroutines for UTF-8 script
 https://metacpan.org/dist/IOas-CP932
 
 IOas::SJIS2004 - provides SJIS2004 I/O subroutines for UTF-8 script
 https://metacpan.org/dist/IOas-SJIS2004
 
 IOas::CP932X - provides CP932X I/O subroutines for UTF-8 script
 https://metacpan.org/dist/IOas-CP932X

=head1 AUTHOR

INABA Hitoshi E<lt>ina@cpan.orgE<gt>

This project was originated by INABA Hitoshi.

=head1 LICENSE AND COPYRIGHT

This software is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
