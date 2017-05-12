
use strict;
use warnings;
use Unicode::UCD;

use constant BIDIRULE_BLKWIDTH => 6;

my $fh;
my $debugfh;
my $init;
my $source;
my $source_file = shift;
if ($source_file and $source_file eq '--init') {
    $init        = 1;
    $source_file = shift;
}
open $fh, '<', $source_file or die $!;
$source = do { local $/; <$fh> };
close $fh;

if ($init) {
    $source =~ s/(#define\s+BIDIRULE_BLKWIDTH)\b.*/$1/
        or die;
    $source =~ s/\b(bidirule_prop_index[[][]]\s*=\s*[{]).*?([}])/$1\n\n$2/s
        or die;
    $source =~ s/\b(bidirule_prop_array[[][]]\s*=\s*[{]).*?([}])/$1\n\n$2/s
        or die;
    $source =~ s/(#define\s+BIDIRULE_UNICODE_VERSION)\b.*/$1/
        or die;
} else {
    open $debugfh, '>', 'propmaps.txt' if $ENV{DEBUG};
    my ($bidi_index, $bidi_array) = build_bidi_map();
    $source =~
        s/(#define\s+BIDIRULE_BLKWIDTH)\b.*/sprintf '%s (%d)', $1, BIDIRULE_BLKWIDTH()/e
        or die;
    $source =~
        s/\b(bidirule_prop_index[[][]]\s*=\s*[{]).*?([}])/$1\n$bidi_index\n$2/s
        or die;
    $source =~
        s/\b(bidirule_prop_array[[][]]\s*=\s*[{]).*?([}])/$1\n$bidi_array\n$2/s
        or die;
    $source =~
        s/(#define\s+BIDIRULE_UNICODE_VERSION)\b.*/sprintf '%s "%s"', $1, Unicode::UCD::UnicodeVersion()/e
        or die;
}

unlink "$source_file.old";
rename $source_file, "$source_file.old" or die $!;
open $fh, '>', $source_file or die $!;
print $fh $source;
close $fh;

sub isDICP {
    my $c = shift;
    my $uc = pack 'U', $c;

    my $ret;
    eval { $ret = ($uc =~ /\A\p{Default_Ignorable_Code_Point}\z/) };
    return $ret unless $@;

    # Earlier Perl 5.8.x did not support DICP class and it have to be derived
    # from ODICP class and so on.  While recent 5.23.x deprecated ODICP class
    # and deny it at compilation time.  So we compute ODICP class at runtime.
    my $ODICPre = eval 'qr/\A\p{Other_Default_Ignorable_Code_Point}\z/';
    die 'Unicode database of your Perl may be broken' unless $ODICPre;
    my $charprop = Unicode::UCD::charinfo($c);
    if ($uc =~ $ODICPre
        or (    $charprop
            and %$charprop
            and $charprop->{category}
            and $charprop->{category} eq 'Cf')
        ) {
        return 0 if $uc =~ /\A\p{White_Space}\z/;
        return 0 if 0xFFF9 <= $c and $c <= 0xFFFB;
        return 0
            if 0x0600 <= $c and $c <= 0x0603
                or $c == 0x06DD
                or $c == 0x070F
                or $c == 0x110BD;
        return 1;
    }
    return 0;
}

sub build_bidi_map {
    my @PROPS = ();

    print STDERR 'Loading property';
    for (my $c = 0x0; $c < 0x020000; $c++) {
        print STDERR '.' unless $c & 0x7FF;

        my $charprop = Unicode::UCD::charinfo($c);
        if ($charprop and %$charprop and $charprop->{bidi}) {
            my $property = $charprop->{bidi};
            $PROPS[$c] =
                  ($property eq 'L') ? 'BDR_LTR'
                : ($property =~ /\A(R|AL)\z/)           ? "BDR_RTL"
                : ($property =~ /\A(ES|CS|ET|ON|BN)\z/) ? "BDR_VALID"
                : ($property =~ /\A(AN|EN|NSM)\z/)      ? "BDR_$property"
                : ($property =~ /\A(LRE|LRO|RLE|RLO|PDF|RLI|LRI|FSI|PDI)\z/)
                ? "BDR_AVOIDED"
                : "BDR_INVALID";
        } elsif (0x0600 <= $c and $c <= 0x07BF
            or 0x08A0 <= $c   and $c <= 0x08FF
            or 0xFB50 <= $c   and $c <= 0xFDCF
            or 0xFDF0 <= $c   and $c <= 0xFDFF
            or 0xFE70 <= $c   and $c <= 0xFEFF
            or 0x01EE00 <= $c and $c <= 0x01EEFF) {
            $PROPS[$c] = 'BDR_RTL';    # AL
        } elsif (0x0590 <= $c and $c <= 0x05FF
            or 0x07C0 <= $c   and $c <= 0x089F
            or 0xFB1D <= $c   and $c <= 0xFB4F
            or 0x010800 <= $c and $c <= 0x010FFF
            or 0x01E800 <= $c and $c <= 0x01EDFF
            or 0x01EF00 <= $c and $c <= 0x01EFFF) {
            $PROPS[$c] = 'BDR_RTL';    # R
        } elsif (0x20A0 <= $c and $c <= 0x20CF) {
            $PROPS[$c] = 'BDR_VALID';    # ET
        } elsif (0xFDD0 <= $c and $c <= 0xFDEF
            or ($c & 0xFFFE) == 0xFFFE
            or isDICP($c)) {
            $PROPS[$c] = "BDR_VALID"     # BN
        }
    }
    print STDERR "\n";

    # Debug
    if ($debugfh) {
        for (my $c = 0; $c < 0x020000; $c++) {
            next unless defined $PROPS[$c];
            printf $debugfh "%04X\t%s\n", $c, $PROPS[$c];
        }
    }

    # Construct compact array.

    my $blklen = 1 << BIDIRULE_BLKWIDTH();

    my @C_ARY = ();
    my @C_IDX = ();
    print STDERR 'Building array..';
    for (my $idx = 0; $idx < 0x20000; $idx += $blklen) {
        print STDERR '.' unless $idx & 0x7FF;

        my @BLK = ();
        for (my $bi = 0; $bi < $blklen; $bi++) {
            my $c = $idx + $bi;
            $BLK[$bi] = $PROPS[$c];
        }
        my ($ci, $bi) = (0, 0);
    C_ARY:
        for ($ci = 0; $ci <= $#C_ARY; $ci++) {
            for ($bi = 0; $bi < $blklen; $bi++) {
                last C_ARY if $#C_ARY < $ci + $bi;
                last
                    unless ($BLK[$bi] || 'BDR_LTR') eq
                    ($C_ARY[$ci + $bi] || 'BDR_LTR');
            }
            last C_ARY if $bi == $blklen;
        }
        push @C_IDX, $ci;
        if ($bi < $blklen) {
            for (; $bi < $blklen; $bi++) {
                push @C_ARY, $BLK[$bi];
            }
        }
    }
    print STDERR "\n";

    # Build compact array index.

    my $index = '';
    my $line  = '';
    foreach my $ci (@C_IDX) {
        if (74 < 4 + length($line) + length(", $ci")) {
            $index .= ",\n" if length $index;
            $index .= "    $line";
            $line = '';
        }
        $line .= ", " if length $line;
        $line .= "$ci";
    }
    $index .= ",\n" if length $index;
    $index .= "    $line";

    # Build compact array.

    my $array = '';
    $line = '';
    foreach my $b (@C_ARY) {
        #die "property unknown\n" unless defined $b;
        my $citem;
        unless (defined $b) {
            $citem = 'BDR_LTR';
        } else {
            $citem = $b;
        }
        if (74 < 4 + length($line) + length(", $citem")) {
            $array .= ",\n" if length $array;
            $array .= "    $line";
            $line = '';
        }
        $line .= ", " if length $line;
        $line .= $citem;
    }
    $array .= ",\n" if length $array;
    $array .= "    $line";

    # Statistics.

    printf STDERR
        "%d codepoints (in BMP, SMP, SIP and TIP), %d entries, %d bytes\n",
        scalar(grep $_, @PROPS), scalar(@C_ARY),
        (0x20000 >> BIDIRULE_BLKWIDTH()) * 2 + scalar(@C_ARY);
    die "Too many entries to work with unsigned 16-bit short integer: "
        . scalar(@C_ARY) . "\n"
        if (1 << 16) <= scalar(@C_ARY);
    warn "Too many entries to work with signed 16-bit pointer: "
        . scalar(@C_ARY) . "\n"
        if (1 << 15) <= scalar(@C_ARY);

    return ($index, $array);
}
