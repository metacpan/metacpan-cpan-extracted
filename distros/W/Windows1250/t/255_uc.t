# encoding: Windows1250
# This file is encoded in Windows-1250.
die "This file is not encoded in Windows-1250.\n" if q{‚ } ne "\x82\xa0";

use strict;
use Windows1250;

my $__FILE__ = __FILE__;

my %uc = ();
@uc{qw(a b c d e f g h i j k l m n o p q r s t u v w x y z)} =
    qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z);
%uc = (%uc,
    "\x9A" => "\x8A",     # LATIN LETTER S WITH CARON
    "\x9C" => "\x8C",     # LATIN LETTER S WITH ACUTE
    "\x9D" => "\x8D",     # LATIN LETTER T WITH CARON
    "\x9E" => "\x8E",     # LATIN LETTER Z WITH CARON
    "\x9F" => "\x8F",     # LATIN LETTER Z WITH ACUTE
    "\xB3" => "\xA3",     # LATIN LETTER L WITH STROKE
    "\xB9" => "\xA5",     # LATIN LETTER A WITH OGONEK
    "\xBA" => "\xAA",     # LATIN LETTER S WITH CEDILLA
    "\xBE" => "\xBC",     # LATIN LETTER L WITH CARON
    "\xBF" => "\xAF",     # LATIN LETTER Z WITH DOT ABOVE
    "\xE0" => "\xC0",     # LATIN LETTER R WITH ACUTE
    "\xE1" => "\xC1",     # LATIN LETTER A WITH ACUTE
    "\xE2" => "\xC2",     # LATIN LETTER A WITH CIRCUMFLEX
    "\xE3" => "\xC3",     # LATIN LETTER A WITH BREVE
    "\xE4" => "\xC4",     # LATIN LETTER A WITH DIAERESIS
    "\xE5" => "\xC5",     # LATIN LETTER L WITH ACUTE
    "\xE6" => "\xC6",     # LATIN LETTER C WITH ACUTE
    "\xE7" => "\xC7",     # LATIN LETTER C WITH CEDILLA
    "\xE8" => "\xC8",     # LATIN LETTER C WITH CARON
    "\xE9" => "\xC9",     # LATIN LETTER E WITH ACUTE
    "\xEA" => "\xCA",     # LATIN LETTER E WITH OGONEK
    "\xEB" => "\xCB",     # LATIN LETTER E WITH DIAERESIS
    "\xEC" => "\xCC",     # LATIN LETTER E WITH CARON
    "\xED" => "\xCD",     # LATIN LETTER I WITH ACUTE
    "\xEE" => "\xCE",     # LATIN LETTER I WITH CIRCUMFLEX
    "\xEF" => "\xCF",     # LATIN LETTER D WITH CARON
    "\xF0" => "\xD0",     # LATIN LETTER D WITH STROKE
    "\xF1" => "\xD1",     # LATIN LETTER N WITH ACUTE
    "\xF2" => "\xD2",     # LATIN LETTER N WITH CARON
    "\xF3" => "\xD3",     # LATIN LETTER O WITH ACUTE
    "\xF4" => "\xD4",     # LATIN LETTER O WITH CIRCUMFLEX
    "\xF5" => "\xD5",     # LATIN LETTER O WITH DOUBLE ACUTE
    "\xF6" => "\xD6",     # LATIN LETTER O WITH DIAERESIS
    "\xF8" => "\xD8",     # LATIN LETTER R WITH CARON
    "\xF9" => "\xD9",     # LATIN LETTER U WITH RING ABOVE
    "\xFA" => "\xDA",     # LATIN LETTER U WITH ACUTE
    "\xFB" => "\xDB",     # LATIN LETTER U WITH DOUBLE ACUTE
    "\xFC" => "\xDC",     # LATIN LETTER U WITH DIAERESIS
    "\xFD" => "\xDD",     # LATIN LETTER Y WITH ACUTE
    "\xFE" => "\xDE",     # LATIN LETTER T WITH CEDILLA
);

printf("1..%d\n", scalar(keys %uc));

my $tno = 1;
for my $char (sort keys %uc){
    if (uc($char) eq $uc{$char}) {
        printf(qq{ok - $tno uc("\\x%02X") eq "\\x%02X" $^X $__FILE__\n}, ord($char), ord($uc{$char}));
    }
    else {
        printf(qq{not ok - $tno uc("\\x%02X") eq "\\x%02X" $^X $__FILE__\n}, ord($char), ord($uc{$char}));
    }
    $tno++;
}

__END__
