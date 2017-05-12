#!perl
use strict;
use utf8;
use warnings qw(all);

use Text::Fingerprint qw(:all);
use Test::More;

my $str = << 'SAMPLE_TEXT';
    À noite, vovô Kowalsky vê o ímã cair no pé do pingüim
    queixoso e vovó põe açúcar no chá de tâmaras do jabuti feliz.
SAMPLE_TEXT

is(
    fingerprint $str,

    q(a acucar cair cha de do e feliz ima jabuti kowalsky) .
    q( no noite o pe pinguim poe queixoso tamaras ve vovo),

    q(fingerprint)
);

is(
    (fingerprint_ngram $str),

    q(abacadaialamanarasbucachcudedoeaedeieleoetevfeg) .
    q(uhaifiminiritixizjakokylilsmamqngnoocoeoiojokop) .
    q(osovowpepipoqurarnsdsksotatetiucueuiutvevowaxoyv),

    q(fingerprint_ngram)
);

is(
    fingerprint_ngram($str, 1),

    q(abcdefghijklmnopqrstuvwxyz),

    q(fingerprint_ngram(..., 1))
);

my $proto = fingerprint_ngram $str, 3;
is(length $proto, 252, q(trigram));
is(
    $proto,
    fingerprint_ngram($str, 3),
    q(prototype),
);

done_testing 5;
