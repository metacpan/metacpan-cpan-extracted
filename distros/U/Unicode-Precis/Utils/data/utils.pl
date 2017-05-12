
use strict;
use warnings;
use Encode qw(encode is_utf8);
use Unicode::UCD qw(charinfo);

my $init;
my $source_file = shift;
if ($source_file and $source_file eq '--init') {
    $init        = 1;
    $source_file = shift;
}

my $fh;
open $fh, '<', $source_file or die $!;
my $source = do { local $/; <$fh> };
close $fh;

if ($init) {
    $source =~
        s{(/\* Begin auto-generated maps \*/).*(/\* End of auto-generated maps \*/)}
   {$1\n\n$2}s
} else {
    my $output = build_map();
    $source =~
        s{(/\* Begin auto-generated maps \*/).*(/\* End of auto-generated maps \*/)}
   {$1\n\n$output$2}s
        or die;
}

unlink "$source_file.old";
rename $source_file, "$source_file.old" or die $!;
open $fh, '>', $source_file or die $!;
print $fh $source;
close $fh;

sub build_map {
    my $map = {};

    print STDERR "Loading property";
    for (my $cp = 0x0; $cp <= 0x3FFFF; $cp++) {
        print STDERR '.' unless $cp & 0xFFF;
        my $charprop = charinfo($cp);
        next unless $charprop and %$charprop;

        my $category = $charprop->{category};
        if ($category and $category eq 'Zs' and $cp != 0x20) {
            die sprintf 'Out of range: U+%02X', $cp
                if $cp < 0x80;

            add_map($map, 'space', $cp, "\x20");
        }

        my $decomposition = $charprop->{decomposition};
        if ($decomposition and $decomposition =~ s/<(?:wide|narrow)>\s*//) {
            die sprintf 'Out of range: U+%02X', $cp
                if $cp < 0x80;

            add_map($map, 'widthdecomp', $cp,
                pack('U*', map { hex "0x$_" } split(/\s+/, $decomposition)));
        }
    }
    print STDERR "\n";

    my $output = '';
    foreach my $mapname (reverse sort keys %$map) {
        $output .= sprintf "static void *%s[%d] = {\n", $mapname,
            scalar(@{$map->{$mapname}});

        my $len = 3;
        $output .= '   ';
        while (@{$map->{$mapname}}) {
            my $c = shift @{$map->{$mapname}};
            $c ||= 'NULL';
            if (75 < $len + length(" $c,")) {
                $output .= "\n   ";
                $len = 3;
            }
            $len += length(" $c,");
            $output .= " $c";
            $output .= ',' if @{$map->{$mapname}};
        }

        $output .= "\n};\n\n";
    }

    return $output;
}

sub add_map {
    my $map     = shift;
    my $mapname = shift() . '_map';
    my $cp      = shift;
    my $dest    = shift;

    my $uc = pack 'U', $cp;
    my $str = encode('UTF-8', $uc);
    my @str = map { ord $_ } split //, $str;

    for (my $i = 0; $i < scalar(@str) - 1; $i++) {
        my $c = $str[$i];
        my $newmapname = sprintf '%s_%02X', $mapname, $c;
        $map->{$mapname} ||= [(undef) x 64];
        $map->{$mapname}->[$c & 0x3F] = $newmapname;
        $mapname = $newmapname;
    }
    $map->{$mapname} ||= [(undef) x 64];
    $map->{$mapname}->[$str[-1] & 0x3F] = sprintf '"%s"', esc($dest);
}

sub esc {
    my $str = shift;
    $str = encode('UTF-8', $str)
        if is_utf8($str);

    $str =~ s{(.)}{sprintf '\\x%02X', ord $1}eg;
    $str;
}
