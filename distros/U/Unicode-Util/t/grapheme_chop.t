use strict;
use warnings;
use utf8;
use open qw( :encoding(UTF-8) :std );
use Test::More tests => 22;
use Test::Warn;
use Unicode::Util qw( grapheme_chop grapheme_length );

my $str = "xя\x{0308}ю\x{0301}";  # xя̈ю́

is grapheme_chop($str), "ю\x{301}", 'grapheme_chop returns the last grapheme';
is $str, "xя\x{0308}", 'grapheme_chop removes the last grapheme';

my $empty = '';
is grapheme_chop($empty), '', 'grapheme_chop returns empty string when passed empty string';
is $empty, '', 'grapheme_chop leaves empty string untouched';

my $undef;
warning_like {
    is grapheme_chop($undef), '', 'grapheme_chop returns empty string when undef';
} qr{^Use of uninitialized value}, 'warns on undef';

$_ = $str;
is grapheme_chop(), "я\x{0308}", 'grapheme_chop returns the last grapheme using $_';
is $_, 'x', 'grapheme_chop removes the last grapheme using $_';

warning_like {
    is grapheme_chop($undef), '', 'grapheme_chop returns empty string when undef and not affected by $_';
} qr{^Use of uninitialized value}, 'warns on undef';
is $_, 'x', '$_ is not affected by grapheme_chop on an undef value';

undef $_;
warning_like {
    is grapheme_chop(), '', 'grapheme_chop returns empty string when undef using $_';
} qr{^Use of uninitialized value}, 'warns on undef';

my @array = ("xxя\x{0308}", "xxю\x{0301}");
is grapheme_chop(@array), "ю\x{301}",
    'grapheme_chop returns the last grapheme of the last element of an array';
is_deeply \@array, ['xx', 'xx'],
    'grapheme_chop removes the last grapheme of each element of an array';

push @array, undef;
warning_like {
    is grapheme_chop(@array), '',
        'grapheme_chop returns empty string when the last element is undef';
} qr{^Use of uninitialized value}, 'warns on undef';
is_deeply \@array, ['x', 'x', undef],
    'grapheme_chop removes the last grapheme but leaves undef as-is';

undef @array;
is grapheme_chop(@array), undef,
    'grapheme_chop returns undef when passed an empty array';

my %hash = (a => "xя\x{0308}", b => "xю\x{0301}");
is grapheme_length( grapheme_chop(%hash) ), 1,
    'return value of grapheme_chop on a hash is not defined but will be one of the chopped graphemes';
is_deeply \%hash, { a => 'x', b => 'x' },
    'grapheme_chop removes the last grapheme of each element of a hash';

undef %hash;
is grapheme_chop(%hash), undef,
    'grapheme_chop returns undef when passed an empty hash';
