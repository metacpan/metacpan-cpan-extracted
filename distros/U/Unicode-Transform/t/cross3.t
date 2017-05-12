
BEGIN { $| = 1; print "1..145\n"; } # 145 = 6 * 6 * 4 + 1

use Unicode::Transform ':all';
use strict;
use warnings;

our $cnt = 1;
print "ok 1\n";

#####

no warnings qw(uninitialized utf8);

our @Codenames = qw(unicode utf32le utf32be utf8 utf8mod utfcp1047);
  # utf16le and utf16be are excluded since they can't encode 0x110000.

our %Src = (
    unicode => "\x{110000}Perl\x{D800}",
    utf32le => "\0\0\x11\0\x50\0\0\0\x65\0\0\0\x72\0\0\0\x6C\0\0\0\0\xD8\0\0",
    utf32be => "\0\x11\0\0\0\0\0\x50\0\0\0\x65\0\0\0\x72\0\0\0\x6C\0\0\xD8\0",
    utf8    => "\xF4\x90\x80\x80\x50\x65\x72\x6C\xED\xA0\x80",
    utf8mod => "\xF9\xA2\xA0\xA0\xA0\x50\x65\x72\x6C\xF1\xB6\xA0\xA0",
  utfcp1047 => "\xEE\x43\x41\x41\x41\xD7\x85\x99\x93\xDD\x65\x41\x41",
);

our %Dst = (
    unicode => "Perl",
    utf32le => "\x50\0\0\0\x65\0\0\0\x72\0\0\0\x6C\0\0\0",
    utf32be => "\0\0\0\x50\0\0\0\x65\0\0\0\x72\0\0\0\x6C",
    utf8    => "\x50\x65\x72\x6C",
    utf8mod => "\x50\x65\x72\x6C",
    utfcp1047 => "\xD7\x85\x99\x93",
);

our %Fbk = (
    unicode => "<110000>Perl<D800>",
    utf32le => "<110000>\x50\0\0\0\x65\0\0\0\x72\0\0\0\x6C\0\0\0<D800>",
    utf32be => "<110000>\0\0\0\x50\0\0\0\x65\0\0\0\x72\0\0\0\x6C<D800>",
    utf8    => "<110000>\x50\x65\x72\x6C<D800>",
    utf8mod => "<110000>\x50\x65\x72\x6C<D800>",
  utfcp1047 => "<110000>\xD7\x85\x99\x93<D800>",
);

#####

sub emp { "" }

sub fbk { sprintf "<%02X>", shift };

our ($cv, $chr);

for my $a (@Codenames) {
    for my $b (@Codenames) {
	eval qq{
	    \$cv = \\&${a}_to_${b};
	    \$chr = \\&chr_${b};
	};
	$@ and die;

	print $cv->($Src{$a}) eq $Dst{$b}
	    ? "ok" : "not ok", " ", ++$cnt, "\n";

	print $cv->($chr, $Src{$a}) eq $Src{$b}
	    ? "ok" : "not ok", " ", ++$cnt, "\n";

	print $cv->(\&emp, $Src{$a}) eq $Dst{$b}
	    ? "ok" : "not ok", " ", ++$cnt, "\n";

	print $cv->(\&fbk, $Src{$a}) eq $Fbk{$b}
	    ? "ok" : "not ok", " ", ++$cnt, "\n";
    }
}

1;


