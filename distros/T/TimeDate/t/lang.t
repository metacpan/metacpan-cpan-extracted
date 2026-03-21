use strict;
use warnings;
use Test::More;
use Date::Language;

my $time = time;

my @lang = qw(
    English German Italian Bulgarian
    French Spanish Swedish Norwegian
    Danish Dutch Romanian Czech
    Hungarian Finnish Austrian Brazilian
    Portuguese Turkish
);

for my $lang (@lang) {
    my $l = Date::Language->new($lang);
    my $str = $l->ctime($time);
    my $parsed = $l->str2time($str);
    is($parsed, $time, "$lang: round-trip ctime/str2time");
}

done_testing;
