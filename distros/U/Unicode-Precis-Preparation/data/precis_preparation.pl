#! perl

use strict;
use warnings;
use Unicode::UCD qw(prop_invmap search_invlist);

use constant PROP_BLKWIDTH  => 6;
use constant AGE_BLKWIDTH   => 5;
use constant XPROP_BLKWIDTH => 7;

my $UnicodeVersion = Unicode::UCD::UnicodeVersion();
die sprintf 'Unicode version mismatch: %s', $UnicodeVersion
    unless $UnicodeVersion eq $ARGV[0];
shift;

my $precis_table = shift;
my $source_file  = shift;

open my $debugfh, '>', 'propmaps.txt' if $ENV{DEBUG};

my ($prop_index,  $prop_array)  = build_prop_map();
my ($age_index,   $age_array)   = build_age_map();
my ($xprop_index, $xprop_array) = build_xprop_map();

my $source = do { local @ARGV = $source_file; local $/; <> };
$source =~
    s/(#define\s+PROP_BLKWIDTH)\b.*/sprintf '%s (%d)', $1, PROP_BLKWIDTH()/e
    or die;
$source =~
    s/(#define\s+AGE_BLKWIDTH)\b.*/sprintf '%s (%d)', $1, AGE_BLKWIDTH()/e
    or die;
$source =~
    s/(#define\s+XPROP_BLKWIDTH)\b.*/sprintf '%s (%d)', $1, XPROP_BLKWIDTH()/e
    or die;
$source =~
    s/\b(precis_prop_index[[][]]\s*=\s*[{]).*?([}])/$1\n$prop_index\n$2/s
    or die;
$source =~
    s/\b(precis_prop_array[[][]]\s*=\s*[{]).*?([}])/$1\n$prop_array\n$2/s
    or die;
$source =~ s/\b(precis_age_index[[][]]\s*=\s*[{]).*?([}])/$1\n$age_index\n$2/s
    or die;
$source =~ s/\b(precis_age_array[[][]]\s*=\s*[{]).*?([}])/$1\n$age_array\n$2/s
    or die;
$source =~
    s/\b(precis_xprop_index[[][]]\s*=\s*[{]).*?([}])/$1\n$xprop_index\n$2/s
    or die;
$source =~
    s/\b(precis_xprop_array[[][]]\s*=\s*[{]).*?([}])/$1\n$xprop_array\n$2/s
    or die;

unlink "$source_file.old";
rename $source_file, "$source_file.old" or die $!;
open my $fh, '>', $source_file or die $!;
print $fh $source;
close $fh;

sub build_prop_map {
    my @PROPS = ();
    my $fh;

    open $fh, '<', $precis_table or die "$precis_table: $!";

    $_ = <$fh>;
    chomp $_;
    my @fields = split /,/, $_;
    die unless @fields;

    print STDERR "RFC 8264 PRECIS Derived Property:\n";

    while (<$fh>) {
        chomp $_;
        @_ = split /,/, $_;
        my %fields = map { (lc $_ => shift @_) } @fields;

        my ($begin, $end) = split /-/, $fields{codepoint}, 2;
        $end ||= $begin;

        my $property = $fields{property};
        $property =~ s/\A(ID_DIS) or FREE_PVAL\z/$1/;

        foreach my $c (hex("0x$begin") .. hex("0x$end")) {
            next unless $c < 0x40000;
            $PROPS[$c] = $property;
        }
    }
    close $fh;

    # Debug
    if ($debugfh) {
        for (my $c = 0; $c < 0x040000; $c++) {
            next unless defined $PROPS[$c];
            printf $debugfh "%04X\t%s\n", $c, $PROPS[$c];
        }
    }

    return construct_compact_array([@PROPS], PROP_BLKWIDTH(), 1);
}

sub build_age_map {
    my @PROPS = ();

    print STDERR "Age:\n";

    my ($list_ref, $map_ref) = prop_invmap('Age');
    for (my $c = 0; $c < 0x40000; $c++) {
        my $idx = search_invlist($list_ref, $c);
        next if $idx < 0;
        my $property = $map_ref->[$idx];
        next unless defined $property and $property =~ /\A\d+([.]\d+)*\z/;

        my @age = split /\./, $property;
        $age[1] ||= 0;
        die sprintf
            "Value for update version found: %s.  Only <major>.<minor> is acceptable",
            $property
            if defined $age[2];

        # Differences by 2.0 and later were tracked by UC.
        $PROPS[$c] = sprintf '0x%02x%02x', @age
            if 2 <= $age[0];
    }

    # Debug
    if ($debugfh) {
        for (my $c = 0; $c < 0x040000; $c++) {
            next unless defined $PROPS[$c];
            printf $debugfh "%04X\t%s\n", $c, $PROPS[$c];
        }
    }

    return construct_compact_array([@PROPS], AGE_BLKWIDTH());
}

sub build_xprop_map {
    my @PROPS = ();

    $PROPS[0x200C] = 'CH_ZWNJ';
    $PROPS[0x200D] = 'CH_ZWJ';
    $PROPS[0x00B7] = 'CH_MIDDLEDOT';
    $PROPS[0x006C] = 'CH_SMALLL';
    $PROPS[0x0375] = 'CH_KERAIA';
    $PROPS[0x05F3] = 'CH_GERESH';
    $PROPS[0x05F4] = 'CH_GERSHAYIM';
    $PROPS[0x30FB] = 'CH_NAKAGURO';
    foreach my $cp (0x0660 .. 0x0669) {
        $PROPS[$cp] = 'CH_Arabic_Indic_digits';
    }
    foreach my $cp (0x06F0 .. 0x06F9) {
        $PROPS[$cp] = 'CH_extended_Arabic_Indic_digits';
    }

    print STDERR "RFC 5892 Contextual Rules:\n";

    my ($sc_list_ref, $sc_map_ref) = prop_invmap('Script');
    for (my $c = 0; $c < 0x40000; $c++) {
        my $idx = search_invlist($sc_list_ref, $c);
        next if $idx < 0;
        my $property = $sc_map_ref->[$idx];
        next
            unless defined $property
            and $property =~ /\A(Greek|Han|Hebrew|Hiragana|Katakana)\z/;

        next if $c == 0x0375;    # KERAIA
        next if $c == 0x05F3;    # GERESH
        next if $c == 0x05F4;    # GERSHAYIM

        $PROPS[$c] = "SC_$property";
    }

    my ($ccc_list_ref, $ccc_map_ref) =
        prop_invmap('Canonical_Combining_Class');
    for (my $c = 0; $c < 0x40000; $c++) {
        my $idx;
        $idx = search_invlist($ccc_list_ref, $c);
        my $ccc = $ccc_map_ref->[$idx] unless $idx < 0;
        next unless defined $ccc and $ccc eq '9';

        die sprintf "Duplicated: U+%04X = %s : CCC_VIRAMA", $c, $PROPS[$c]
            if defined $PROPS[$c];
        $PROPS[$c] = 'CCC_VIRAMA';
    }

    my ($jt_list_ref, $jt_map_ref) = prop_invmap('Joining_Type');
    for (my $c = 0; $c < 0x40000; $c++) {
        my $idx = search_invlist($jt_list_ref, $c);
        next if $idx < 0;
        my $property = $jt_map_ref->[$idx];
        next unless defined $property and $property =~ /\A[DLTR]\z/;

        if (defined $PROPS[$c]) {
            $PROPS[$c] = sprintf 'JT_%s | %s', $property, $PROPS[$c];
        } else {
            $PROPS[$c] = sprintf 'JT_%s', $property;
        }
    }

    # Debug
    if ($debugfh) {
        for (my $c = 0; $c < 0x040000; $c++) {
            next unless defined $PROPS[$c];
            printf $debugfh "%04X\t%s\n", $c, $PROPS[$c];
        }
    }

    return construct_compact_array([@PROPS], XPROP_BLKWIDTH());
}

# Construct compact array.
sub construct_compact_array {
    my $PROPS       = shift;
    my $block_width = shift;
    my $complete    = shift;

    my @PROPS = @$PROPS;

    my $blklen = 1 << $block_width;

    my @C_ARY = ();
    my @C_IDX = ();
    for (my $idx = 0; $idx < 0x40000; $idx += $blklen) {
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
                if ($complete) {
                    last unless $BLK[$bi] eq $C_ARY[$ci + $bi];
                } else {
                    last
                        unless ($BLK[$bi] || '0') eq
                        ($C_ARY[$ci + $bi] || '0');
                }
            }
            last C_ARY if $bi == $blklen;
        }
        push @C_IDX, $ci;
        if ($bi < $blklen) {
            for (; $bi < $blklen; $bi++) {
                push @C_ARY, $BLK[$bi];
            }
        }
        printf STDERR "U+%04X..U+%04X: %d..%d / %d      \r", $idx,
            $idx + ($blklen) - 1, $ci, $ci + ($blklen) - 1, scalar @C_ARY;
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
        my $citem;
        if ($complete) {
            die "property unknown\n" unless defined $b;
            $citem = 'PRECIS_' . $b;
        } else {
            unless (defined $b) {
                $citem = '0';
            } else {
                $citem = $b;
            }
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
        (0x40000 >> $block_width) * 2 + scalar(@C_ARY);
    die "Too many entries to work with unsigned 16-bit short integer: "
        . scalar(@C_ARY) . "\n"
        if (1 << 16) <= scalar(@C_ARY);
    warn "Too many entries to work with signed 16-bit pointer: "
        . scalar(@C_ARY) . "\n"
        if (1 << 15) <= scalar(@C_ARY);

    return ($index, $array);
}

