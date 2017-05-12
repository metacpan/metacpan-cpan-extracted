
BEGIN { $| = 1; print "1..321\n"; } # 321 = 8 * 8 * 5 + 1

use Unicode::Transform ':conv';
use strict;
use warnings;

our $cnt = 1;
print "ok 1\n";

#####

our @Codenames =
    qw(unicode utf16le utf16be utf32le utf32be utf8 utf8mod utfcp1047);

our %Null = (
    unicode => "\0",
    utf16le => "\0\0",
    utf16be => "\0\0",
    utf32le => "\0\0\0\0",
    utf32be => "\0\0\0\0",
    utf8    => "\0",
    utf8mod => "\0",
    utfcp1047 => "\0",
);

our %Perl = (
    unicode => "Perl",
    utf16le => "\x50\0\x65\0\x72\0\x6C\0",
    utf16be => "\0\x50\0\x65\0\x72\0\x6C",
    utf32le => "\x50\0\0\0\x65\0\0\0\x72\0\0\0\x6C\0\0\0",
    utf32be => "\0\0\0\x50\0\0\0\x65\0\0\0\x72\0\0\0\x6C",
    utf8    => "\x50\x65\x72\x6C",
    utf8mod => "\x50\x65\x72\x6C",
    utfcp1047 => "\xD7\x85\x99\x93",
);

our %Feff = (
    unicode => "\x{feff}",
    utf16le => "\xFF\xFE",
    utf16be => "\xFE\xFF",
    utf32le => "\xFF\xFE\0\0",
    utf32be => "\0\0\xFE\xFF",
    utf8    => "\xEF\xBB\xBF",
    utf8mod => "\xF1\xBF\xB7\xBF",
    utfcp1047 => "\xDD\x73\x66\x73",
);

#####

our $cv;

for my $a (@Codenames) {
    for my $b (@Codenames) {
	eval qq{ \$cv = \\&${a}_to_${b} };
	$@ and die;

	print $cv->("") eq ""
	    ? "ok" : "not ok", " ", ++$cnt, "\n";

	print $cv->($Null{$a}) eq $Null{$b}
	    ? "ok" : "not ok", " ", ++$cnt, "\n";

	print $cv->($Perl{$a}) eq $Perl{$b}
	    ? "ok" : "not ok", " ", ++$cnt, "\n";

	print $cv->($Feff{$a}) eq $Feff{$b}
	    ? "ok" : "not ok", " ", ++$cnt, "\n";

	print $cv->("$Perl{$a}$Null{$a}$Feff{$a}")
		 eq "$Perl{$b}$Null{$b}$Feff{$b}"
	    ? "ok" : "not ok", " ", ++$cnt, "\n";
    }
}

1;


