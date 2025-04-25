use strict;
use warnings;
use Unicode::Normalize qw(NFKC);
use Unicode::UCD qw(charinfo charprop);

my $UnicodeVersion = Unicode::UCD::UnicodeVersion();
die sprintf 'Unicode version mismatch: %s', $UnicodeVersion
    unless $UnicodeVersion eq $ARGV[0];

print "Codepoint,Property\n";

my (@range, $prop);
my $cp;
for ($cp = 0; $cp < 0x40000; $cp++) {
    my $p = property($cp);
    unless (@range) {
	@range = ($cp, $cp);
	$prop = $p;
    } elsif ($range[1] + 1 == $cp and $prop eq $p) {
	$range[1] = $cp;
    } else {
	if ($range[0] == $range[1]) {
            printf "%04X,%s\n", $range[0], $prop;
	} else {
	    printf "%04X-%04X,%s\n", @range, $prop;
	}
	@range = ($cp, $cp);
	$prop = $p;
   }

   printf STDERR "%04X\r", $cp unless $cp % 16;
} 
if (@range) {
    if ($range[0] == $range[1]) {
        printf "%04X,%s\n", $range[0], $prop;
    } else {
	printf "%04X-%04X,%s\n", @range, $prop;
    }
}

for ($cp = 0x40000; $cp < 0xE0000; $cp += 0x10000) {
    printf <<'EOF', $cp, $cp + 0xFFFD, $cp + 0xFFFE, $cp + 0xFFFF;
%04X-%04X,UNASSIGNED
%04X-%04X,DISALLOWED
EOF
}

print <<'EOF';
E0000,UNASSIGNED
E0001,DISALLOWED
E0002-E001F,UNASSIGNED
E0020-E007F,DISALLOWED
E0080-E00FF,UNASSIGNED
E0100-E01EF,DISALLOWED
E01F0-EFFFD,UNASSIGNED
EFFFE-10FFFF,DISALLOWED
EOF

exit 0;

sub property {
    my $cp = shift;

    if (0x3400 <= $cp and $cp <= 0x4DB5) {
	# CJK Unified Ideographs Extension A.
	return 'PVALID';
    } elsif (0x4E00 <= $cp and $cp <= 0x9FCC) {
	# CJK Unified Ideographs.
	return 'PVALID';
    } elsif (0xAC00 <= $cp and $cp <= 0xD7A3) {
	# Hangul Syllables.
	return 'PVALID';
    } elsif (0xD800 <= $cp and $cp <= 0xF8FF) {
	# Surrogates & Private use.
	return 'DISALLOWED';
    } elsif (0x20000 <= $cp and $cp <= 0x2A6D6
        or 0x2A700 <= $cp and $cp <= 0x2B734
        or 0x2B740 <= $cp and $cp <= 0x2B81D) {
	# CJK Unified Ideographs Extension B, C, D.
	return 'PVALID';
    }

    my $charinfo = charinfo($cp);
    my $gc = $charinfo->{category} if $charinfo and %$charinfo;

    # See RFC 8264, 8.
    if (defined catExceptions($cp)) {
        catExceptions($cp);
    } elsif (defined catBackwardCompatible($cp)) {
        catBackwardCompatible($cp);
    } elsif (catUnassigned($cp, $gc)) {
        'UNASSIGNED';
    } elsif (catASCII7($cp)) {
        'PVALID';
    } elsif (catJoinControl($cp)) {
        'CONTEXTJ';
    } elsif (catOldHangulJamo($cp)) {
        'DISALLOWED';
    } elsif (catPrecisIgnorableProperties($cp)) {
        'DISALLOWED';
    } elsif (catControls($cp)) {
        'DISALLOWED';
    } elsif (catHasCompat($cp)) {
        'ID_DIS or FREE_PVAL';
    } elsif (catLetterDigits($cp, $gc)) {
        'PVALID';
    } elsif (catOtherLetterDigits($cp, $gc)) {
        'ID_DIS or FREE_PVAL';
    } elsif (catSpaces($cp, $gc)) {
        'ID_DIS or FREE_PVAL';
    } elsif (catSymbols($cp, $gc)) {
        'ID_DIS or FREE_PVAL';
    } elsif (catPunctuation($cp, $gc)) {
        'ID_DIS or FREE_PVAL';
    } else {
        'DISALLOWED';
    }
}

sub catLetterDigits { # (A)
    my $cp = shift;
    my $gc = shift;

    return $gc && scalar grep {$gc eq $_} qw(Ll Lu Lo Nd Lm Mn Mc);
}

sub catExceptions { # (F)
    my $cp = shift;

    # See RFC 5892, 2.6.
    if (grep {$cp == $_} (0x00DF, 0x03C2, 0x06FD, 0x06FE, 0x0F0B, 0x3007)) {
	'PVALID';
    } elsif (grep {$cp == $_} (0x00B7, 0x0375, 0x05F3, 0x05F4, 0x30FB)) {
	'CONTEXTO';
    } elsif (grep {$cp == $_} (0x0660 .. 0x0669, 0x06F0 .. 0x06F9)) {
	'CONTEXTO';
    } elsif (grep {$cp == $_}
	(0x0640, 0x07FA, 0x302E, 0x302F, 0x3031 .. 0x3035, 0x303B)) {
	'DISALLOWED';
    } else {
	undef;
    }
}

sub catBackwardCompatible { # (G)
    undef;
}

sub catJoinControl { # (H)
    my $cp = shift;

    return charprop($cp, 'Join_Control') eq 'Yes';
}

sub catOldHangulJamo { # (I)
    my $cp = shift;

    my $hst = charprop($cp, 'Hangul_Syllable_Type');
    return $hst && scalar grep {$hst eq $_}
	qw(Leading_Jamo Trailing_Jamo Vowel_Jamo);
}

sub catUnassigned { # (J)
    my $cp = shift;
    my $gc = shift;

    return (!$gc || $gc eq 'Cn')
        && !isNoncharacter_Code_Point($cp);
}

sub catASCII7 { # (K)
    my $cp = shift;

    return 0x0021 <= $cp && $cp <= 0x007E;
}

sub catControls { # (L)
    my $cp = shift;

    return 0x0000 <= $cp && $cp <= 0x001F
        || 0x007F <= $cp && $cp <= 0x009F;
}

sub catPrecisIgnorableProperties { # (M)
    my $cp = shift;

    return isDefault_Ignorable_Code_Point($cp)
        || isNoncharacter_Code_Point($cp);
}

sub catSpaces { # (N)
    my $cp = shift;
    my $gc = shift;

    return $gc && $gc eq 'Zs';
}

sub catSymbols { # (O)
    my $cp = shift;
    my $gc = shift;

    return $gc && scalar grep {$gc eq $_} qw(Sm Sc Sk So);
}

sub catPunctuation { # (P)
    my $cp = shift;
    my $gc = shift;

    return $gc && scalar grep {$gc eq $_} qw(Pc Pd Ps Pe Pi Pf Po);
}

sub catHasCompat { # (Q)
    my $cp = shift;

    return NFKC(chr $cp) ne (chr $cp);
}

sub catOtherLetterDigits { # (R)
    my $cp = shift;
    my $gc = shift;

    return $gc && scalar grep {$gc eq $_} qw(Lt Nl No Me);
}


sub isNoncharacter_Code_Point {
    my $cp = shift;

    return (0xFDD0 <= $cp && $cp <= 0xFDEF)
        || ($cp & 0xFFFE) == 0xFFFE;
}

sub isDefault_Ignorable_Code_Point {
    my $cp = shift;

    return charprop($cp, 'Default_Ignorable_Code_Point') eq 'Yes';
}

