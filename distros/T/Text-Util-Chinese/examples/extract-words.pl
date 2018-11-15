use v5.18;
use strict;
use warnings;
use Encode qw(encode_utf8 decode_utf8);
use Text::Util::Chinese 'extract_words';

open my $fh, '<', $ARGV[0];

my $words = extract_words(
    sub {
        my $x = <$fh>;
        return decode_utf8 $x;
    });

say encode_utf8($_) for @$words;
