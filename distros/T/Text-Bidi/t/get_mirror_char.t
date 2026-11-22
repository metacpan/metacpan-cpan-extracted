use strict;
use warnings;
use open qw[:encoding(UTF-8) :std];
use Test::More;
use version 0.77;
use Text::Bidi qw(get_mirror_char unicode_version);

my $unicode = version->parse(unicode_version());

# Source code points added to BidiMirroring.txt in Unicode 11.0 and 14.0.
# FriBidi returns the input character before its table has a mapping.
my %unmapped;
if ($unicode < v11.0.0) {
    $unmapped{$_} = 1 for qw(
        221F 2220 2221 2222 2224 2245 224C 22B8 27DC 299B 29A0 29A3
        29A4 29A5 29A8 29A9 29AA 29AB 29AC 29AD 29AE 29AF 29E8 29E9
        2A7B 2A7C 2A85 2A86 2A87 2A88 2A89 2A8A 2A8D 2A8E 2A8F 2A90
        2A9D 2A9E 2A9F 2AA0 2AB1 2AB2 2AB5 2AB6 2AB7 2AB8 2AB9 2ABA
        2AC7 2AC8 2AC9 2ACA 2ACB 2ACC 2AEE 2BFE
    );
}
if ($unicode < v14.0.0) {
    $unmapped{$_} = 1 for qw(2E55 2E56 2E57 2E58 2E59 2E5A 2E5B 2E5C);
}

open my $fh, '<', 't/MirrorTest.txt' 
    or plan skip_all => "can't open mirror table: $!";


foreach ( <$fh> ) {
    next if /^\s*(#|$)/;
    chomp;
    if ( /^([0-9A-F]{4,6}); ([0-9A-F]{4,6}) # (.*)$/ ) {
        my ($source, $mirror, $description) = ($1, $2, $3);
        my $expected = $unmapped{$source} ? $source : $mirror;
        is scalar(get_mirror_char(chr(hex($source)))), chr(hex($expected)),
            "Mirror for U+$source ($description)";
    }
}

done_testing;

