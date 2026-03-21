use strict;
use warnings;
use Test::More;
use Date::Language;

# RT#113419 / GH#19: Language modules must return Unicode strings (UTF-8 flagged),
# not raw byte strings in legacy encodings.
#
# Legacy encoding modules (Chinese_GB, Russian, Russian_koi8r, Russian_cp1251)
# intentionally return byte strings and are excluded from this check.

my @unicode_langs = qw(
    Afar
    Amharic
    Arabic
    Austrian
    Brazilian
    Bulgarian
    Chinese
    Czech
    Danish
    Dutch
    English
    Finnish
    French
    Gedeo
    German
    Greek
    Hungarian
    Icelandic
    Italian
    Norwegian
    Occitan
    Oromo
    Romanian
    Sidama
    Somali
    Spanish
    Swedish
    Tigrinya
    TigrinyaEritrean
    TigrinyaEthiopian
    Turkish
);

# Tue Sep  7 13:02:42 1999 GMT
my $time = 936709362;

for my $lang (@unicode_langs) {
    my $l = Date::Language->new($lang);

    for my $fmt (qw(%A %a %B %b)) {
        my $str = $l->time2str($fmt, $time, 'GMT');

        # Pure-ASCII strings don't get the UTF-8 flag; skip them.
        next unless $str =~ /[^\x00-\x7f]/;

        ok(
            utf8::is_utf8($str),
            "$lang $fmt: non-ASCII result has UTF-8 flag set"
        );
    }
}

done_testing;
