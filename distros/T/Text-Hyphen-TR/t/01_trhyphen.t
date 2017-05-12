#!/usr/bin/perl
use strict;
use warnings;

use utf8;

use Test::More qw/no_plan/;

use Text::Hyphen::TR;

ok(my $hyp = new Text::Hyphen::TR, 'hyphenator loaded');

sub is_hyph ($$) {
    my ($word, $expected) = @_;
    my $result = $hyp->hyphenate($word);
    is($result, $expected, qq{hyphenated another word});
}

is_hyph 'çektirilebilecek', 'çek-ti-ri-le-bi-lecek';
is_hyph 'çektirilebileceği', 'çek-ti-ri-le-bi-le-ce-ği';
is_hyph 'Türkçeyi', 'Türk-çe-yi';
is_hyph 'bilgisayar', 'bil-gi-sa-yar';
is_hyph 'antrparantez', 'antr-pa-ran-tez';
is_hyph 'kusturucu', 'kus-tu-ru-cu';
is_hyph 'bakacak', 'ba-kacak';
