use 5.10.0;
use strict;
use warnings;
use Test::More;
use Text::Bidi::Paragraph;
use Text::Bidi::Constants;

# Download BidiCharacterTest.txt for the library's Unicode version from
# https://www.unicode.org/Public/<version>/ucd/BidiCharacterTest.txt
my $file = $ENV{TEXT_BIDI_CHARACTER_TEST};
plan skip_all => 'Set TEXT_BIDI_CHARACTER_TEST to a Unicode BidiCharacterTest.txt file'
    unless defined $file;
open my $fh, '<', $file or die "Cannot open $file: $!";

my @dirs = ($Text::Bidi::Par::LTR, $Text::Bidi::Par::RTL, $Text::Bidi::Par::ON);
while (<$fh>) {
    next if /^\s*(?:#|$)/;
    chomp;
    my $line = $.;
    my ($codes, $dir, $base, $levels, $map) = split /;/;
    my $text = join '', map { chr hex } split ' ', $codes;
    my @levels = split ' ', $levels;
    my $p = Text::Bidi::Paragraph->new($text, dir => $dirs[$dir], shape => undef);
    # The character conformance tests exclude shaping and NSM reordering.
    $p->visual(0, $p->len, 0);
    my @actual = @{$p->levels};
    for my $i (0..$#levels) {
        $actual[$i] = 'x' if $levels[$i] eq 'x';
    }
    is $p->is_rtl ? 1 : 0, $base, "paragraph direction at line $line";
    is "@actual", $levels, "embedding levels at line $line";
    my @map = grep { $levels[$_] ne 'x' } @{$p->map};
    is "@map", $map, "reordering at line $line";
}

done_testing;
